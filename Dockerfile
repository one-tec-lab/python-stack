FROM python:3
ENV PYTHONUNBUFFERED 1
RUN mkdir /code
WORKDIR /code
COPY requirements.txt /code/
COPY wait-for-it.sh /code/
RUN pip install -r requirements.txt
COPY . /code/
