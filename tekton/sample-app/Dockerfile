FROM registry.access.redhat.com/ubi8/ubi-minimal:latest
RUN microdnf install -y nginx && microdnf clean all
RUN echo "<h1>Hello from Harbor CI/CD Pipeline</h1>" > /usr/share/nginx/html/index.html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
