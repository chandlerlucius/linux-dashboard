package com.utils.dashboard;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import javax.websocket.EncodeException;
import javax.websocket.OnClose;
import javax.websocket.OnError;
import javax.websocket.OnMessage;
import javax.websocket.OnOpen;
import javax.websocket.Session;
import javax.websocket.server.ServerEndpoint;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * This class is responsible for handling the messaging system between the
 * clients and server using Java Websocket API.
 * 
 * @author Chandler Lucius
 * @version 1.0.0
 * @since 1.0.0
 */
@ServerEndpoint("/websocket")
public class WebSocket {

    private static final Logger LOG = LoggerFactory.getLogger(WebSocket.class);
    private static final String TMP_DIR = System.getProperty("java.io.tmpdir");
    private static final int BUFFER_LENGTH = 1024;
    private static final String SEP = File.separator;
    private static final Set<Session> SESSION_SET = new HashSet<>();
    private static final Map<String, Integer> PROPERTY_MAP = new ConcurrentHashMap<>();

    static {
        copyScriptToTempDir("/sh/ServerStats.sh", "ServerStats.sh");
        final String json = runServerScript("groups");
        try {
            final ObjectMapper objectMapper = new ObjectMapper();
            final JsonNode jsonNode = objectMapper.readTree(json);
            final JsonNode groups = jsonNode.get("groups");
            if (groups != null && groups.isArray()) {
                for (final JsonNode group : groups) {
                    final JsonNode subgroups = group.get("subgroups");
                    if (subgroups != null && subgroups.isArray()) {
                        for (final JsonNode subgroup : subgroups) {
                            final JsonNode properties = subgroup.get("properties");
                            if (properties != null && properties.isArray()) {
                                for (final JsonNode property : properties) {
                                    final int interval = property.get("interval").asInt(1000);
                                    final String message = property.get("id").asText();
                                    PROPERTY_MAP.put(message, interval);
                                }
                            }
                        }
                    }
                }
            }
        } catch (final JsonProcessingException e) {
            LOG.error("Issue parsing JSON: ", e);
        }
        startScript();
    }

    WebSocket() {
        // Empty on purpose
    }

    private static void startScript() {
        for (final Map.Entry<String, Integer> entry : PROPERTY_MAP.entrySet()) {
            final Runnable runScript = new Runnable() {
                @Override
                public void run() {
                    sendMessagesToClients(entry.getKey());
                }
            };
            final ScheduledExecutorService executor = Executors.newScheduledThreadPool(1);
            executor.scheduleAtFixedRate(runScript, 0, entry.getValue(), TimeUnit.MILLISECONDS);
        }
    }

    private static void sendMessagesToClients(final String message) {
        try {
            final String json = runServerScript(message);
            final Iterator<Session> iterator = SESSION_SET.iterator();
            while (iterator.hasNext()) {
                final Session session = iterator.next();
                if (session.isOpen()) {
                    synchronized (session) {
                        session.getBasicRemote().sendObject(json);
                    }
                } else {
                    SESSION_SET.remove(session);
                }
            }
        } catch (IOException | EncodeException e) {
            LOG.error("Error sending message: ", e);
        }
    }

    @OnOpen
    public void open(final Session session) {
        SESSION_SET.add(session);
        LOG.info("Opened websocket connection: {} - {}", SESSION_SET.size(), session.getId());

        try {
            final String groups = runServerScript("groups");
            session.getBasicRemote().sendObject(groups);
            for (final Map.Entry<String, Integer> entry : PROPERTY_MAP.entrySet()) {
                final String json = runServerScript(entry.getKey());
                session.getBasicRemote().sendObject(json);
            }
        } catch (IOException | EncodeException e) {
            LOG.error("Issue sending group json: ", e);
        }
    }

    @OnClose
    public void close(final Session session) {
        SESSION_SET.remove(session);
        LOG.info("Closed websocket connection: {} - {}", SESSION_SET.size(), session.getId());
    }

    @OnMessage
    public void handleMessage(final String message, final Session session) {
        try {
            // final long startTime = System.nanoTime();
            // LOG.info("Begin - " + message);
            final String result = runServerScript(message);
            // final long elapsedTime = System.nanoTime() - startTime;
            // LOG.info("End - " + message + " | Elapsed seconds : " + ((double) elapsedTime
            // / 1_000_000_000.0));
            session.getBasicRemote().sendText(result);
        } catch (final IOException e) {
            LOG.error("Issue sending data to websocket: ", e);
        }
    }

    @OnError
    public void onError(final Throwable throwable) {
        LOG.error("Issue with websocket connection: ", throwable);
    }

    public static final String copyScriptToTempDir(final String inputFilePath, final String outputFileName) {
        try (InputStream inputStream = WebSocket.class.getResourceAsStream(inputFilePath)) {
            if (inputStream != null) {
                final File tempFile = new File(TMP_DIR + SEP + outputFileName);
                Files.copy(inputStream, tempFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
                if (!tempFile.setExecutable(true)) {
                    LOG.error("Failed to make temp file executable.");
                }
                return tempFile.getPath();
            }
        } catch (final IOException e) {
            LOG.error("Issue copying file to temp directory: ", e);
        }
        return "";
    }

    private static String runServerScript(final String bashFunction) {
        String retVal = "";
        Process process = null;
        try {
            final File tempFile = new File(TMP_DIR + "/ServerStats.sh");
            final ProcessBuilder processBuilder = new ProcessBuilder(tempFile.getAbsolutePath(), bashFunction);
            processBuilder.directory(new File(TMP_DIR));
            processBuilder.redirectErrorStream(true);
            processBuilder.start();

            process = processBuilder.start();
            process.waitFor();
        } catch (IOException e) {
            LOG.error("Issue running script: ", e);
        } catch (InterruptedException e) {
            LOG.error("Issue running script: ", e);
            Thread.currentThread().interrupt();
        }

        if (process != null) {
            try (InputStream inputStream = process.getInputStream();
                    ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
                final byte[] buffer = new byte[BUFFER_LENGTH];
                int length;
                while ((length = inputStream.read(buffer)) != -1) {
                    baos.write(buffer, 0, length);
                }
                retVal = baos.toString(StandardCharsets.UTF_8.name());
            } catch (final IOException e) {
                LOG.error("Issue retrieving script output: ", e);
            }
        }
        return retVal;
    }
}
