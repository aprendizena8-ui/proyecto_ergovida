from locust import HttpUser, task, between

class ErgoVidaUser(HttpUser):
    wait_time = between(0.5, 1.5)

    @task
    def check_home(self):
        self.client.get("/")
