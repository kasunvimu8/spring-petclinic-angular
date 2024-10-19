# Define arguments for Docker Hub, Nginx, and Node.js versions
ARG DOCKER_HUB="docker.io"
ARG NGINX_VERSION="1.25-alpine"
ARG NODE_VERSION="18.18-alpine"

# Use the specified Node.js version as the build image
FROM $DOCKER_HUB/library/node:$NODE_VERSION AS build

# Set the working directory
WORKDIR /workspace

# Copy the application code to the container
COPY . .

# Set the NPM registry (ensure there is no leading space)
ARG NPM_REGISTRY="https://registry.npmjs.org"

# Install dependencies and build the application
RUN echo "registry = \"$NPM_REGISTRY\"" > .npmrc && \
    npm install && \
    npm run build

# Use the specified Nginx version as the runtime image
FROM $DOCKER_HUB/library/nginx:$NGINX_VERSION AS runtime

# Install curl for the healthcheck
RUN apk add --no-cache curl

# Copy the build output from the previous stage to Nginx's HTML directory
COPY --from=build /workspace/dist/ /usr/share/nginx/html/

# Adjust permissions and Nginx configuration
RUN chmod a+rwx /var/cache/nginx /var/run /var/log/nginx && \
    sed -i.bak 's/listen\(.*\)80;/listen 8080;/' /etc/nginx/conf.d/default.conf && \
    sed -i.bak 's/^user/#user/' /etc/nginx/nginx.conf

# Expose port 8080
EXPOSE 8080

# Set the user to nginx
USER nginx

# Healthcheck using curl
HEALTHCHECK CMD curl --fail http://localhost:8080/ || exit 1
