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

        // String version = System.getProperty("java.version");
        // System.out.println("Java version " + version);
        // if(version.charAt(0) == '1' && Integer.parseInt(version.charAt(2) + "") < 8 )
        // {
        // System.out.println("This example requires Java 1.8 or later");
        // System.out.println("The HTTP2 spec requires certain cyphers that are not
        // present in older JVM's");
        // System.out.println("See section 9.2.2 of the HTTP2 specification for
        // details");
        // System.exit(1);
        // }
        // String bindAddress = System.getProperty("bind.address", "localhost");
        // SSLContext sslContext = createSSLContext(loadKeyStore("server.keystore"),
        // loadKeyStore("server.truststore"));
        // Undertow server = Undertow.builder()
        // .setServerOption(UndertowOptions.ENABLE_HTTP2, true)
        // .addHttpListener(8080, "localhost").build();
        // .addHttpsListener(8443, bindAddress, sslContext)
        // .setHandler(new SessionAttachmentHandler(new LearningPushHandler(100, -1,
        // Handlers.header(predicate(secure(), resource(new
        // PathResourceManager(Paths.get(System.getProperty("example.directory",
        // System.getProperty("user.home"))), 100))
        // .setDirectoryListingEnabled(true), new HttpHandler() {
        // @Override
        // public void handleRequest(HttpServerExchange exchange) throws Exception {
        // exchange.getResponseHeaders().add(Headers.LOCATION, "https://" +
        // exchange.getHostName() + ":" + (exchange.getHostPort() + 363) +
        // exchange.getRelativePath());
        // exchange.setStatusCode(StatusCodes.TEMPORARY_REDIRECT);
        // }
        // }), "x-undertow-transport", ExchangeAttributes.transportProtocol())), new
        // InMemorySessionManager("test"), new SessionCookieConfig())).build();

        // server.start();

        // SSLContext clientSslContext =
        // createSSLContext(loadKeyStore("client.keystore"),
        // loadKeyStore("client.truststore"));
        // LoadBalancingProxyClient proxy = new LoadBalancingProxyClient()
        // .addHost(new URI("https://localhost:8443"), null, new
        // UndertowXnioSsl(Xnio.getInstance(), OptionMap.EMPTY, clientSslContext),
        // OptionMap.create(UndertowOptions.ENABLE_HTTP2, true))
        // .setConnectionsPerThread(20);

        // Undertow reverseProxy = Undertow.builder()
        // .setServerOption(UndertowOptions.ENABLE_HTTP2, true)
        // .addHttpListener(8081, bindAddress)
        // .addHttpsListener(8444, bindAddress, sslContext)
        // .setHandler(ProxyHandler.builder().setProxyClient(proxy).setMaxRequestTime(
        // 30000).build())
        // .build();
        // reverseProxy.start();

    }

    // private static KeyStore loadKeyStore(String name) throws Exception {
    // String storeLoc = System.getProperty(name);
    // final InputStream stream;
    // if(storeLoc == null) {
    // stream = Http2Server.class.getResourceAsStream(name);
    // } else {
    // stream = Files.newInputStream(Paths.get(storeLoc));
    // }

    // if(stream == null) {
    // throw new RuntimeException("Could not load keystore");
    // }
    // try(InputStream is = stream) {
    // KeyStore loadedKeystore = KeyStore.getInstance("JKS");
    // loadedKeystore.load(is, password(name));
    // return loadedKeystore;
    // }
    // }

    // static char[] password(String name) {
    // String pw = System.getProperty(name + ".password");
    // return pw != null ? pw.toCharArray() : STORE_PASSWORD;
    // }

    // private static SSLContext createSSLContext(final KeyStore keyStore, final
    // KeyStore trustStore) throws Exception {
    // KeyManager[] keyManagers;
    // KeyManagerFactory keyManagerFactory =
    // KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
    // keyManagerFactory.init(keyStore, password("key"));
    // keyManagers = keyManagerFactory.getKeyManagers();

    // TrustManager[] trustManagers;
    // TrustManagerFactory trustManagerFactory =
    // TrustManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
    // trustManagerFactory.init(trustStore);
    // trustManagers = trustManagerFactory.getTrustManagers();

    // SSLContext sslContext;
    // sslContext = SSLContext.getInstance("TLS");
    // sslContext.init(keyManagers, trustManagers, null);

    // return sslContext;
    // }

}
