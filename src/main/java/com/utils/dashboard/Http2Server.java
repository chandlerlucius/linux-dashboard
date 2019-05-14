package com.utils.dashboard;

import javax.servlet.ServletException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import io.undertow.Handlers;
import io.undertow.Undertow;
import io.undertow.Undertow.Builder;
import io.undertow.server.DefaultByteBufferPool;
import io.undertow.server.handlers.PathHandler;
import io.undertow.server.handlers.resource.ClassPathResourceManager;
import io.undertow.servlet.api.DeploymentInfo;
import io.undertow.servlet.api.DeploymentManager;
import io.undertow.servlet.api.ServletContainer;
import io.undertow.servlet.core.ServletContainerImpl;
import io.undertow.websockets.jsr.WebSocketDeploymentInfo;

/**
 * This class is responsible for setting up and starting the embedded undertow server used for the
 * application.
 * 
 * @author Chandler Lucius
 * @version 1.0.0
 * @since 1.0.0
 */
public final class Http2Server {

    private static final Logger LOG = LoggerFactory.getLogger(Http2Server.class);
    private static final int BUFFER_SIZE = 100;
    private static final int PORT = 8080;
    private static final String IP = "0.0.0.0";

    private Http2Server() {
    }

    public static void main(final String[] args) {
        final PathHandler path = Handlers.path();
        final Builder builder = Undertow.builder();
        builder.addHttpListener(PORT, IP);
        builder.setHandler(path);

        final Undertow server = builder.build();
        server.start();

        final WebSocketDeploymentInfo wsDeploymentInfo = new WebSocketDeploymentInfo();
        wsDeploymentInfo.setBuffers(new DefaultByteBufferPool(true, BUFFER_SIZE));
        wsDeploymentInfo.addEndpoint(WebSocket.class);

        final ClassLoader classLoader = ClassLoader.getSystemClassLoader();
        final DeploymentInfo deploymentInfo = new DeploymentInfo();
        deploymentInfo.setContextPath("/");
        deploymentInfo.setClassLoader(classLoader);
        deploymentInfo.addWelcomePage("index.html");
        deploymentInfo.setDeploymentName("linux-dashboard.war");
        deploymentInfo.setResourceManager(
                new ClassPathResourceManager(classLoader, "com/utils/dashboard/"));
        deploymentInfo.addServletContextAttribute(WebSocketDeploymentInfo.ATTRIBUTE_NAME,
                wsDeploymentInfo);

        final ServletContainer container = new ServletContainerImpl();
        container.addDeployment(deploymentInfo);

        final DeploymentManager manager = container.getDeployment("linux-dashboard.war");
        manager.deploy();
        try {
            path.addPrefixPath("/", manager.start());
        } catch (ServletException e) {
            LOG.error("Issue starting deploy: ", e);
        }
    }
}
