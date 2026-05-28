FROM leanprover/lean4:v4.29.1 AS build
WORKDIR /workspace
COPY . .
RUN lake build

FROM leanprover/lean4:v4.29.1
WORKDIR /workspace
COPY --from=build /workspace /workspace
EXPOSE 8080
CMD ["lake", "exe", "lfse", "--", "serve", "--host", "0.0.0.0", "--port", "8080"]
