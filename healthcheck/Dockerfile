# Start with the base image
FROM ubuntu:20.04

# Set the working directory
WORKDIR /app

# Copy the application code into the container
COPY . /app/

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y \
    curl \
    gnupg \
    apt-transport-https \
    lsb-release \
    openjdk-11-jre-headless && \
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl" && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    kubectl version --client && \
    # Install Kafka CLI tools
    curl -LO "https://downloads.apache.org/kafka/3.5.2/kafka_2.13-3.5.2.tgz" && \
    tar -xzf kafka_2.13-3.5.2.tgz && \
    mv kafka_2.13-3.5.2 /usr/local/kafka && \
    ln -s /usr/local/kafka/bin/kafka* /usr/local/bin/ && \
    # Clean up
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm kafka_2.13-3.5.2.tgz

RUN mkdir /app/config
