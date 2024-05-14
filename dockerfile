# Stage 1: Get Helm from alpine/helm image
FROM alpine/helm as helm

# Stage 2: Build final image with runner-terraform and Helm
FROM public.ecr.aws/spacelift/runner-terraform:latest

# Copy Helm binary from the first stage
COPY --from=helm /usr/bin/helm /usr/bin/helm