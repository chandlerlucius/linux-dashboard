package com.utils.dashboard;

import java.io.*;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.*;
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
import io.undertow.server.*;
import io.undertow.server.handlers.PathHandler;
import io.undertow.server.handlers.resource.ClassPathResourceManager;
import io.undertow.servlet.api.*;
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
    private static final String KEYSTORE_FILE = "keystore.file";
    private static final String KEYSTORE_PWD = "keystore.password";

    private Http2Server() {
    }

    public static void main(final String[] args) throws FileNotFoundException {
        // Determine location of running code or jar
        String propertiesPath = "";
        try {
            final CodeSource codeSource = Http2Server.class.getProtectionDomain().getCodeSource();
            final File codeLocation = new File(codeSource.getLocation().toURI().getPath());
            final String codePath = codeLocation.getParentFile().getPath();
            final File propertiesFile = new File(codePath + "/application.properties");
            if (propertiesFile.exists()) {
                propertiesPath = propertiesFile.getPath();
            }
        } catch (URISyntaxException e) {
            LOG.error("Issue getting code/jar location: ", e);
        }

        // Load properties from application.properties file
        final Properties properties = new Properties();
        if (!propertiesPath.isEmpty()) {
            try (InputStream inputStream = Files.newInputStream(Paths.get(propertiesPath))) {
                properties.load(inputStream);
            } catch (IOException e) {
                LOG.error("Issue reading properties file: ", e);
            }
        }

        final int httpPort = Integer.parseInt(properties.getProperty(HTTP_PORT_PROP, HTTP_PORT));
        final int httpsPort = Integer.parseInt(properties.getProperty(HTTPS_PORT_PROP, HTTPS_PORT));
        final String keystoreFile = properties.getProperty(KEYSTORE_FILE, "");
        final String keystorePassword = properties.getProperty(KEYSTORE_PWD, "");

        final PathHandler path = Handlers.path();
        final Builder builder = Undertow.builder();
        builder.setHandler(path);

        if (!keystoreFile.isEmpty() && !keystorePassword.isEmpty()) {
            final SSLContext sslContext = generateSslContext(keystoreFile, keystorePassword.toCharArray());

            builder.setServerOption(UndertowOptions.ENABLE_HTTP2, true);
            builder.addHttpsListener(httpsPort, IP_ADDRESS, sslContext);

            builder.addHttpListener(httpPort, IP_ADDRESS, new HttpHandler() {
                @Override
                public void handleRequest(final HttpServerExchange exchange) throws Exception {
                    exchange.getResponseHeaders().add(Headers.LOCATION,
                            "https://" + exchange.getHostName() + ":" + httpsPort
                                    + exchange.getRelativePath());
                    exchange.setStatusCode(StatusCodes.TEMPORARY_REDIRECT);
                }
            });
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

    private static SSLContext generateSslContext(final String keystoreFile, final char[] keystorePassword) {
        SSLContext sslContext = null;
        try (InputStream inputStream = Files.newInputStream(Paths.get(keystoreFile))) {
            final KeyStore keystore = KeyStore.getInstance("PKCS12");
            keystore.load(inputStream, keystorePassword);

            KeyManager[] keyManagers;
            final KeyManagerFactory keyManagerFactory =
                    KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
            keyManagerFactory.init(keystore, keystorePassword);
            keyManagers = keyManagerFactory.getKeyManagers();

            KeyStore truststore = null;
            TrustManager[] trustManagers;
            final TrustManagerFactory managerFactory =
                    TrustManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
            managerFactory.init(truststore);
            trustManagers = managerFactory.getTrustManagers();

            sslContext = SSLContext.getInstance("TLSv1.2");
            sslContext.init(keyManagers, trustManagers, null);
        } catch (KeyStoreException | NoSuchAlgorithmException | CertificateException | IOException
                | KeyManagementException | UnrecoverableKeyException e) {
            LOG.error("Issue loading keystore or ssl context.", e);
        }
        return sslContext;
    }
}
