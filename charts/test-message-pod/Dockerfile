# Dockerfile for curl-demo-pod with Kafka tools and dependencies
# Based on curlimages/curl:8.10.1 with Java 11 and Kafka 3.9.0
# Extended with bash, grpcurl, and debugging tools

FROM curlimages/curl:8.10.1

USER root

# Install bash, OpenJDK 11, kcat, and debugging tools
RUN apk add --no-cache \
    bash \
    openjdk11-jre \
    kcat \
    wget \
    ca-certificates \
    openssl \
    jq \
    vim \
    nano \
    net-tools \
    bind-tools \
    iputils \
    tcpdump \
    sudo

# Download and extract Kafka 3.9.0
WORKDIR /tmp
RUN curl -L -O https://archive.apache.org/dist/kafka/3.9.0/kafka_2.13-3.9.0.tgz && \
    tar -xzf kafka_2.13-3.9.0.tgz && \
    mv kafka_2.13-3.9.0 /tmp/kafka && \
    rm kafka_2.13-3.9.0.tgz

# Download required dependencies
WORKDIR /tmp/kafka/libs
RUN curl -L -o scala-library-2.13.12.jar \
    https://repo1.maven.org/maven2/org/scala-lang/scala-library/2.13.12/scala-library-2.13.12.jar && \
    curl -L -o scalalogging_2.13-3.9.5.jar \
    https://repo1.maven.org/maven2/com/typesafe/scala-logging/scalalogging_2.13/3.9.5/scalalogging_2.13-3.9.5.jar && \
    curl -L -o slf4j-api-2.0.9.jar \
    https://repo1.maven.org/maven2/org/slf4j/slf4j-api/2.0.9/slf4j-api-2.0.9.jar && \
    curl -L -o slf4j-reload4j-2.0.9.jar \
    https://repo1.maven.org/maven2/org/slf4j/slf4j-reload4j/2.0.9/slf4j-reload4j-2.0.9.jar && \
    curl -L -o reload4j-1.2.25.jar \
    https://repo1.maven.org/maven2/ch/qos/reload4j/reload4j/1.2.25/reload4j-1.2.25.jar && \
    curl -L -o aws-msk-iam-auth-2.3.0-all.jar \
    https://github.com/aws/aws-msk-iam-auth/releases/download/v2.3.0/aws-msk-iam-auth-2.3.0-all.jar

# Install grpcurl
RUN wget -qO- https://github.com/fullstorydev/grpcurl/releases/download/v1.9.1/grpcurl_1.9.1_linux_x86_64.tar.gz | \
    tar xz -C /usr/local/bin grpcurl && \
    chmod +x /usr/local/bin/grpcurl

# Set environment variables for Kafka
ENV PATH="/tmp/kafka/bin:${PATH}"
ENV KAFKA_HOME="/tmp/kafka"
ENV SHELL=/bin/bash

# Verify installations
RUN bash --version && \
    java -version && \
    grpcurl --version && \
    kcat -V && \
    echo "All tools installed successfully"

# Create /tmp/data directory and set permissions
RUN mkdir -p /tmp/data && chmod 777 /tmp

# Copy test data file for easy testing
COPY test-data.trig /tmp/test-data.trig
RUN chmod 644 /tmp/test-data.trig

# Create MSK producer configuration file
RUN echo "security.protocol=SASL_SSL" > /tmp/msk-producer.properties && \
    echo "sasl.mechanism=AWS_MSK_IAM" >> /tmp/msk-producer.properties && \
    echo "sasl.jaas.config=software.amazon.msk.auth.iam.IAMLoginModule required;" >> /tmp/msk-producer.properties && \
    echo "sasl.client.callback.handler.class=software.amazon.msk.auth.iam.IAMClientCallbackHandler" >> /tmp/msk-producer.properties && \
    chmod 644 /tmp/msk-producer.properties

# Give curl_user sudo access without password
RUN echo "curl_user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch back to curl user for security
USER curl_user

WORKDIR /tmp

# Default command - use sh to ensure compatibility
CMD ["/bin/sh", "-c", "sleep infinity"]
