package com.utils.dashboard;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.server.standard.ServerEndpointExporter;

/**
 * Weird extra class needed for Spring Boot to allow regular Java Websockets
 */
@Configuration
public class EndpointConfig {

    public EndpointConfig() {
        // This constructor is intentionally empty. Nothing special is needed here.
    }

    @Bean
    public WebSocket webSocket() {
        return new WebSocket();
    }

    @Bean
    public ServerEndpointExporter endpointExporter() {
        return new ServerEndpointExporter();
    }

}