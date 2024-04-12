# Use the official Node.js 16 image as the base image
FROM node:16

# Set the working directory in the container to /app
WORKDIR /app

# Copy the package.json file into the container at /app
COPY package*.json ./

# Install all the dependencies
RUN npm install

# Copy the rest of the application code into the container at /app
COPY . .

# Set the PORT environment variable to 8080
ENV PORT=3000

# Expose the port the app runs on
EXPOSE 3000

# Start the application, no shell form
CMD ["node", "server.js"]


# docker build -t server .
# docker run -p 5001:5174 2a859592d84d18455c58c20ab7d1f63441c2187f10dc833476e1874754bcde27
