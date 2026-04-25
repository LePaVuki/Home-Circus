# Ollama LLM provider, configured to run on host CPU
FROM ollama/ollama

# Update repositories and install curl
RUN apt-get update -y && apt-get install curl -y

# Cleanup to reduce image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/*