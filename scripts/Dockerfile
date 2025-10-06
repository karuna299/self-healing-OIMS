# Use Python base image
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install Ansible
RUN pip install flask

# Copy webhook receiver script
COPY scripts/ansible_webhook_receiver.py /app/

# Expose webhook port
EXPOSE 5001

# Run the webhook receiver
CMD ["python", "ansible_webhook_receiver.py"]