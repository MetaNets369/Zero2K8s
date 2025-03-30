    # Use official Python runtime as a parent image
    FROM python:3.9-slim

    # Set the working directory in the container
    WORKDIR /app

    # Copy the requirements file into the container at /app
    # Path is relative to the build context (now ./docker)
    COPY ../cop/requirements.txt .

    # Install any needed packages specified in requirements.txt
    RUN pip install --no-cache-dir -r requirements.txt

    # Copy the main application file into the container at /app
    # Path is relative to the build context (now ./docker)
    COPY ../cop/main.py .

    # Make port 5000 available to the world outside this container
    EXPOSE 5000

    # Define environment variable (optional)
    # ENV NAME World

    # Run uvicorn server when the container launches
    # Use 0.0.0.0 to ensure it's accessible from outside the container
    CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5000"]
    