from locust import HttpUser, task, between

class SREUser(HttpUser):
    wait_time = between(0.1, 0.5)

    @task
    def test_aplicar_descuento(self):
        self.client.post("/aplicar-descuento")