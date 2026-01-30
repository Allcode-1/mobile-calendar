FROM python:3.10-slim

WORKDIR /app

# copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# copy the rest code of the server
COPY . .

# expose the port
EXPOSE 8000

# run
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]