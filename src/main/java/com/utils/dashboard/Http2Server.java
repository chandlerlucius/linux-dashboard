package com.utils.dashboard;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
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
import javax.net.ssl.KeyManager;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.servlet.ServletException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import io.undertow.Handlers;
import io.undertow.Undertow;
import io.undertow.Undertow.Builder;
import io.undertow.UndertowOptions;
import io.undertow.server.DefaultByteBufferPool;
import io.undertow.server.HttpHandler;
import io.undertow.server.HttpServerExchange;
import io.undertow.server.handlers.PathHandler;
import io.undertow.server.handlers.resource.ClassPathResourceManager;
import io.undertow.servlet.api.DeploymentInfo;
import io.undertow.servlet.api.DeploymentManager;
import io.undertow.servlet.api.ServletContainer;
import io.undertow.servlet.core.ServletContainerImpl;
import io.undertow.util.Headers;
import io.undertow.util.StatusCodes;
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
    private static final String HTTP_PORT = "8080";
    private static final String HTTPS_PORT = "8443";
    private static final String IP_ADDRESS = "0";

    private static final String HTTP_PORT_PROP = "http.port";
    private static final String HTTPS_PORT_PROP = "https.port";
    private static final String KEYSTORE_FILE_PROP = "keystore.file";
    private static final String KEYSTORE_PWD_PROP = "keystore.password";

    private Http2Server() {
    }

    public static void main(final String[] args) throws FileNotFoundException {
        // Determine location of running code or jar
        String propertiesPath = "";
        try {
            CodeSource codeSource = Http2Server.class.getProtectionDomain().getCodeSource();
            File codeLocation = new File(codeSource.getLocation().toURI().getPath());
            String codePath = codeLocation.getParentFile().getPath();
            File propertiesFile = new File(codePath + "/application.properties");
            if (propertiesFile.exists()) {
                propertiesPath = propertiesFile.getPath();
            }
        } catch (URISyntaxException e) {
            LOG.error("Issue getting code/jar location: ", e);
        }

        // Load properties from application.properties file
        Properties properties = new Properties();
        if (!propertiesPath.isEmpty()) {
            try (InputStream inputStream = new FileInputStream(propertiesPath)) {
                properties.load(inputStream);
            } catch (Exception e) {
                LOG.error("Issue reading properties file: ", e);
            }
        }

        int httpPort = Integer.parseInt(properties.getProperty(HTTP_PORT_PROP, HTTP_PORT));
        int httpsPort = Integer.parseInt(properties.getProperty(HTTPS_PORT_PROP, HTTPS_PORT));
        String keystoreFile = properties.getProperty(KEYSTORE_FILE_PROP, "");
        String keystorePassword = properties.getProperty(KEYSTORE_PWD_PROP, "");

        if (httpPort == 0 || httpsPort == 0) {
            LOG.error("Provide a valid http.port or https.port!");
            System.exit(1);
        }

        final PathHandler path = Handlers.path();
        final Builder builder = Undertow.builder();
        builder.setHandler(path);

        if (!keystoreFile.isEmpty() || !keystorePassword.isEmpty()) {
            try (InputStream inputStream = new FileInputStream(keystoreFile)) {
                KeyStore keystore = KeyStore.getInstance("PKCS12");
                keystore.load(inputStream, keystorePassword.toCharArray());

                KeyManager[] keyManagers;
                KeyManagerFactory keyManagerFactory =
                        KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
                keyManagerFactory.init(keystore, keystorePassword.toCharArray());
                keyManagers = keyManagerFactory.getKeyManagers();

                KeyStore truststore = null;
                TrustManager[] trustManagers;
                TrustManagerFactory trustManagerFactory =
                        TrustManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
                trustManagerFactory.init(truststore);
                trustManagers = trustManagerFactory.getTrustManagers();

                SSLContext sslContext;
                sslContext = SSLContext.getInstance("TLSv1.2");
                sslContext.init(keyManagers, trustManagers, null);

                builder.setServerOption(UndertowOptions.ENABLE_HTTP2, true);
                builder.addHttpsListener(httpsPort, IP_ADDRESS, sslContext);

                builder.addHttpListener(httpPort, IP_ADDRESS, new HttpHandler() {
                    @Override
                    public void handleRequest(HttpServerExchange exchange) throws Exception {
                        exchange.getResponseHeaders().add(Headers.LOCATION,
                                "https://" + exchange.getHostName() + ":" + httpsPort
                                        + exchange.getRelativePath());
                        exchange.setStatusCode(StatusCodes.TEMPORARY_REDIRECT);
                    }
                });
            } catch (KeyStoreException | NoSuchAlgorithmException | CertificateException
                    | IOException | KeyManagementException | UnrecoverableKeyException e) {
                LOG.error("Issue loading keystore or ssl context.", e);
            }
        } else {
            builder.addHttpListener(httpPort, IP_ADDRESS);
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
