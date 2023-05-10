FROM python:3.9

RUN python3 -m pip install httpserver

WORKDIR /home
ENTRYPOINT ["python3", "-m", "http.server", "8080"]