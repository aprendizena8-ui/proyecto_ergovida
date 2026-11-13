package com.ergovida.backend.service;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.Signature;
import java.security.spec.PKCS8EncodedKeySpec;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Envia notificaciones push con Firebase Cloud Messaging (HTTP v1).
 *
 * Las credenciales se leen exclusivamente de variables de entorno:
 *   FIREBASE_SERVICE_ACCOUNT_PATH  ruta al JSON de la cuenta de servicio.
 *   FIREBASE_SERVICE_ACCOUNT_JSON  contenido JSON (alternativa a la ruta).
 *   FIREBASE_PROJECT_ID            project_id de Firebase.
 *   FCM_ENABLED=true               habilita el envio.
 */
@Service
public class FcmPushService {

    private static final Logger logger =
            LoggerFactory.getLogger(FcmPushService.class);

    private static final String SCOPE =
            "https://www.googleapis.com/auth/firebase.messaging";
    private static final String TOKEN_URI_POR_DEFECTO =
            "https://oauth2.googleapis.com/token";
    private static final String ENDPOINT_POR_DEFECTO =
            "https://fcm.googleapis.com/v1/projects/%s/messages:send";

    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;
    private final boolean habilitado;
    private final String rutaCuentaServicio;
    private final String jsonCuentaServicio;
    private final String projectIdConfigurado;

    private volatile Credenciales credenciales;
    private volatile boolean credencialesIntentadas;
    private volatile String accessToken;
    private volatile Instant accessTokenExpira = Instant.EPOCH;

    public FcmPushService(
            ObjectMapper objectMapper,
            @Value("${ergovida.push.enabled:false}") boolean habilitado,
            @Value("${ergovida.push.service-account-path:}") String rutaCuentaServicio,
            @Value("${ergovida.push.service-account-json:}") String jsonCuentaServicio,
            @Value("${ergovida.push.project-id:}") String projectIdConfigurado) {
        this.objectMapper = objectMapper;
        this.habilitado = habilitado;
        this.rutaCuentaServicio = rutaCuentaServicio;
        this.jsonCuentaServicio = jsonCuentaServicio;
        this.projectIdConfigurado = projectIdConfigurado;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
    }

    public boolean estaConfigurado() {
        return habilitado && obtenerCredenciales() != null;
    }

    public ResultadoPush enviar(
            String token,
            String titulo,
            String cuerpo,
            Map<String, String> datos) {

        if (!habilitado) {
            return ResultadoPush.omitido("FCM no esta habilitado (FCM_ENABLED).");
        }

        Credenciales cred = obtenerCredenciales();
        if (cred == null) {
            return ResultadoPush.omitido(
                    "Firebase no esta configurado (cuenta de servicio).");
        }

        if (token == null || token.isBlank()) {
            return ResultadoPush.omitido("Token de dispositivo vacio.");
        }

        try {
            String access = obtenerAccessToken(cred);

            Map<String, Object> mensaje = new LinkedHashMap<>();
            mensaje.put("token", token);
            mensaje.put(
                    "notification",
                    Map.of(
                            "title", titulo == null ? "ErgoVida" : titulo,
                            "body", cuerpo == null ? "" : cuerpo));
            if (datos != null && !datos.isEmpty()) {
                mensaje.put("data", datos);
            }
            mensaje.put("android", Map.of("priority", "HIGH"));
            mensaje.put(
                    "apns",
                    Map.of(
                            "headers", Map.of("apns-priority", "10"),
                            "payload", Map.of(
                                    "aps", Map.of("sound", "default"))));

            String payload = objectMapper.writeValueAsString(
                    Map.of("message", mensaje));

            String url = String.format(
                    ENDPOINT_POR_DEFECTO,
                    cred.projectId());

            HttpRequest request = HttpRequest.newBuilder(URI.create(url))
                    .timeout(Duration.ofSeconds(15))
                    .header("Authorization", "Bearer " + access)
                    .header("Content-Type", "application/json; charset=UTF-8")
                    .POST(HttpRequest.BodyPublishers.ofString(
                            payload, StandardCharsets.UTF_8))
                    .build();

            HttpResponse<String> response = httpClient.send(
                    request,
                    HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));

            if (response.statusCode() >= 200 && response.statusCode() < 300) {
                return ResultadoPush.ok();
            }

            String detalle = "HTTP " + response.statusCode() + ": "
                    + recortar(response.body());
            boolean tokenInvalido = response.statusCode() == 404
                    || contieneTokenInvalido(response.body());
            return ResultadoPush.error(detalle, tokenInvalido);

        } catch (Exception error) {
            logger.warn(
                    "No se pudo enviar la notificacion push: {}",
                    error.getMessage());
            return ResultadoPush.error(error.getMessage(), false);
        }
    }

    private String obtenerAccessToken(Credenciales cred) throws Exception {
        Instant ahora = Instant.now();
        if (accessToken != null
                && ahora.isBefore(accessTokenExpira.minusSeconds(60))) {
            return accessToken;
        }

        long iat = ahora.getEpochSecond();
        long exp = iat + 3600;

        Map<String, Object> claims = new LinkedHashMap<>();
        claims.put("iss", cred.clientEmail());
        claims.put("scope", SCOPE);
        claims.put("aud", cred.tokenUri());
        claims.put("iat", iat);
        claims.put("exp", exp);

        String header = base64Url(
                "{\"alg\":\"RS256\",\"typ\":\"JWT\"}");
        String cuerpo = base64Url(objectMapper.writeValueAsString(claims));
        String sinFirma = header + "." + cuerpo;

        Signature firma = Signature.getInstance("SHA256withRSA");
        firma.initSign(cred.privateKey());
        firma.update(sinFirma.getBytes(StandardCharsets.UTF_8));
        String jwt = sinFirma + "." + base64Url(firma.sign());

        String formulario = "grant_type="
                + URLEncoder.encode(
                        "urn:ietf:params:oauth:grant-type:jwt-bearer",
                        StandardCharsets.UTF_8)
                + "&assertion="
                + URLEncoder.encode(jwt, StandardCharsets.UTF_8);

        HttpRequest request = HttpRequest.newBuilder(URI.create(cred.tokenUri()))
                .timeout(Duration.ofSeconds(15))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(formulario))
                .build();

        HttpResponse<String> response = httpClient.send(
                request,
                HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));

        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IllegalStateException(
                    "No se pudo obtener el token de Firebase: "
                            + recortar(response.body()));
        }

        JsonNode node = objectMapper.readTree(response.body());
        String token = node.path("access_token").asText("");
        if (token.isBlank()) {
            throw new IllegalStateException(
                    "Firebase no devolvio access_token.");
        }

        long expiraEn = node.path("expires_in").asLong(3600);
        accessToken = token;
        accessTokenExpira = ahora.plusSeconds(expiraEn);
        return token;
    }

    private Credenciales obtenerCredenciales() {
        if (credencialesIntentadas) {
            return credenciales;
        }

        synchronized (this) {
            if (credencialesIntentadas) {
                return credenciales;
            }
            credencialesIntentadas = true;

            try {
                String json = jsonCuentaServicio;
                if ((json == null || json.isBlank())
                        && rutaCuentaServicio != null
                        && !rutaCuentaServicio.isBlank()) {
                    json = Files.readString(
                            Path.of(rutaCuentaServicio.trim()),
                            StandardCharsets.UTF_8);
                }

                if (json == null || json.isBlank()) {
                    logger.info(
                            "FCM habilitado sin cuenta de servicio configurada. "
                                    + "Se enviaran solo correos.");
                    return null;
                }

                JsonNode node = objectMapper.readTree(json);
                String clientEmail = node.path("client_email").asText("");
                String privateKeyPem = node.path("private_key").asText("");
                String projectId = firstNonBlank(
                        projectIdConfigurado,
                        node.path("project_id").asText(""));
                String tokenUri = firstNonBlank(
                        node.path("token_uri").asText(""),
                        TOKEN_URI_POR_DEFECTO);

                if (clientEmail.isBlank()
                        || privateKeyPem.isBlank()
                        || projectId.isBlank()) {
                    logger.warn(
                            "La cuenta de servicio FCM no tiene client_email, "
                                    + "private_key o project_id.");
                    return null;
                }

                PrivateKey privateKey = leerLlavePrivada(privateKeyPem);
                credenciales = new Credenciales(
                        clientEmail,
                        privateKey,
                        projectId,
                        tokenUri);
                logger.info(
                        "FCM configurado para el proyecto {}", projectId);
                return credenciales;

            } catch (Exception error) {
                logger.error(
                        "No se pudo cargar la cuenta de servicio FCM: {}",
                        error.getMessage());
                return null;
            }
        }
    }

    private static PrivateKey leerLlavePrivada(String pem) throws Exception {
        String limpia = pem
                .replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replaceAll("\\s+", "");
        byte[] bytes = Base64.getDecoder().decode(limpia);
        return KeyFactory.getInstance("RSA")
                .generatePrivate(new PKCS8EncodedKeySpec(bytes));
    }

    private static String base64Url(String valor) {
        return Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString(valor.getBytes(StandardCharsets.UTF_8));
    }

    private static String base64Url(byte[] valor) {
        return Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString(valor);
    }

    private static boolean contieneTokenInvalido(String cuerpo) {
        if (cuerpo == null) {
            return false;
        }
        String texto = cuerpo.toUpperCase();
        return texto.contains("UNREGISTERED")
                || texto.contains("NOT_FOUND")
                || texto.contains("INVALID_ARGUMENT");
    }

    private static String firstNonBlank(String... valores) {
        for (String valor : valores) {
            if (valor != null && !valor.isBlank()) {
                return valor.trim();
            }
        }
        return "";
    }

    private static String recortar(String valor) {
        if (valor == null) {
            return "";
        }
        String limpio = valor.replaceAll("\\s+", " ").trim();
        return limpio.length() > 500 ? limpio.substring(0, 500) : limpio;
    }

    private record Credenciales(
            String clientEmail,
            PrivateKey privateKey,
            String projectId,
            String tokenUri) {
    }

    public record ResultadoPush(
            boolean exito,
            boolean omitido,
            boolean tokenInvalido,
            String error) {

        public static ResultadoPush ok() {
            return new ResultadoPush(true, false, false, null);
        }

        public static ResultadoPush error(String error, boolean tokenInvalido) {
            return new ResultadoPush(false, false, tokenInvalido, error);
        }

        public static ResultadoPush omitido(String motivo) {
            return new ResultadoPush(false, true, false, motivo);
        }
    }
}
