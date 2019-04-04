package com.utils.dashboard;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.server.standard.ServerEndpointExporter;

/**
 * Weird extra class needed for Spring Boot to allow regular Java Websockets
 */
@Configuration
public class EndpointConfig {

    @Bean
    public DashboardWebSocket dashboardWebSocket() {
        return new DashboardWebSocket();
    }

    @Bean
    public ServerEndpointExporter endpointExporter() {
        return new ServerEndpointExporter();
    }

}