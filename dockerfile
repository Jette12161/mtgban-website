FROM golang:1.19 AS build

WORKDIR /app

COPY go.mod go.sum ./

RUN git config --global url."git@github.com:".insteadOf "https://github.com/"
RUN mkdir -p /root/.ssh && \
    ssh-keyscan github.com > /root/.ssh/known_hosts

COPY id_rsa /root/.ssh/id_rsa
RUN eval $(ssh-agent) && \
    ssh-add /root/.ssh/id_rsa && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -a -o app .

FROM nginx:latest

COPY --from=build /app/app /usr/share/nginx/html
COPY --from=build /app/css /usr/share/nginx/css
COPY --from=build /app/img /usr/share/nginx/img
COPY --from=build /app/js /usr/share/nginx/js
COPY --from=build /app/templates /usr/share/nginx/templates

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
