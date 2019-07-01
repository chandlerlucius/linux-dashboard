package com.utils.dashboard;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URISyntaxException;
import java.security.CodeSource;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;
import java.util.Properties;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.servlet.ServletException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import io.undertow.Handlers;
import io.undertow.Undertow;
import io.undertow.Undertow.Builder;
import io.undertow.UndertowOptions;
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
    private static final int HTTP_PORT = 8080;
    private static final int HTTPS_PORT = 8443;
    private static final String IP_ADDRESS = "0.0.0.0";

    private static final String PROPERTIES_FILE_PROP = "properties.file";
    private static final String HTTP_PORT_PROP = "http.port";
    private static final String HTTPS_PORT_PROP = "https.port";
    private static final String KEYSTORE_FILE_PROP = "keystore.file";
    private static final String KEYSTORE_PASSWORD_PROP = "keystore.password";

    private Http2Server() {
    }

    public static void main(final String[] args) {
        // Determine location of jar
        String propertiesFilePath = "";
        try {
            CodeSource codeSource = Http2Server.class.getProtectionDomain().getCodeSource();
            File jarFile = new File(codeSource.getLocation().toURI().getPath());
            String jarPath = jarFile.getParentFile().getPath();
            File propertiesFile = new File(jarPath + "/application.properties");
            if (propertiesFile.exists()) {
                propertiesFilePath = propertiesFile.getPath();
            }
        } catch (URISyntaxException e) {
            System.err.println(e);
        }

        // Load properties from passed in argument file or jar path
        Properties properties = new Properties();
        String propertiesPath = System.getProperty(PROPERTIES_FILE_PROP, propertiesFilePath);
        if (propertiesPath != null && !propertiesPath.isEmpty()) {
            try (InputStream inputStream = new FileInputStream(propertiesPath)) {
                properties.load(inputStream);
            } catch (Exception e) {
                // LOG.error("Issue retrieving certificate and setting up HTTPS: ", e);
                System.err.println(e);
            }
        } else {
            try (InputStream inputStream =
                    Http2Server.class.getResourceAsStream("/application.properties")) {
                properties.load(inputStream);
            } catch (Exception e) {
                // LOG.error("Issue retrieving certificate and setting up HTTPS: ", e);
                System.err.println(e);
            }
        }

        // Try to pull properties from command line arguments and then properties file
        String httpProp =
                System.getProperty(HTTP_PORT_PROP, properties.getProperty(HTTP_PORT_PROP));
        int httpPort =
                httpProp != null && !httpProp.isEmpty() ? Integer.parseInt(httpProp) : HTTP_PORT;

        String httpsProp =
                System.getProperty(HTTPS_PORT_PROP, properties.getProperty(HTTPS_PORT_PROP));
        int httspPort = httpsProp != null && !httpsProp.isEmpty() ? Integer.parseInt(httpsProp)
                : HTTPS_PORT;

        String keystoreFile =
                System.getProperty(KEYSTORE_FILE_PROP, properties.getProperty(KEYSTORE_FILE_PROP));
        String keystorePassword = System.getProperty(KEYSTORE_PASSWORD_PROP,
                properties.getProperty(KEYSTORE_PASSWORD_PROP));

        final PathHandler path = Handlers.path();
        final Builder builder = Undertow.builder();

        builder.addHttpListener(httpPort, IP_ADDRESS);
        builder.setHandler(path);

        if (keystoreFile != null && keystorePassword != null && !keystoreFile.isEmpty()
                && !keystorePassword.isEmpty()) {
            try (InputStream inputStream = new FileInputStream(keystoreFile)) {
                System.out.println(keystoreFile);
                KeyStore keyStore = KeyStore.getInstance("JKS");
                keyStore.load(inputStream, keystorePassword.toCharArray());

                KeyManagerFactory keyManagerFactory =
                        KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
                keyManagerFactory.init(keyStore, keystorePassword.toCharArray());

                SSLContext sslContext = SSLContext.getInstance("TLS");
                sslContext.init(keyManagerFactory.getKeyManagers(), null, null);

                // Add HTTPS listener and enable HTTP2
                builder.addHttpsListener(httspPort, IP_ADDRESS, sslContext);
                // builder.setServerOption(UndertowOptions.ENABLE_HTTP2, true);
            } catch (IOException | UnrecoverableKeyException | KeyStoreException
                    | NoSuchAlgorithmException | CertificateException | KeyManagementException e) {
                // LOG.error("Issue retrieving certificate and setting up HTTPS: ", e);
                System.err.println(e);
            }
        }

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
        deploymentInfo.setResourceManager(new ClassPathResourceManager(classLoader, "webapp"));
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
