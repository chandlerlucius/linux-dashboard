package com.utils.dashboard;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;
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
    private static final String SEP = File.separator;
    private static final Set<Session> sessions = new HashSet<>();
    private static final Map<String, Integer> propertiesMap = new HashMap<>();

    static {
        copyScriptToTempDir("/sh/ServerStats.sh", "ServerStats.sh");
        String json = runServerScript("groups");
        try {
            ObjectMapper objectMapper = new ObjectMapper();
            JsonNode jsonNode = objectMapper.readTree(json);
            JsonNode groups = jsonNode.get("groups");
            if (groups != null && groups.isArray()) {
                for (final JsonNode group : groups) {
                    JsonNode subgroups = group.get("subgroups");
                    if (subgroups != null && subgroups.isArray()) {
                        for (final JsonNode subgroup : subgroups) {
                            JsonNode properties = subgroup.get("properties");
                            if (properties != null && properties.isArray()) {
                                for (final JsonNode property : properties) {
                                    int interval = property.get("interval").asInt(1000);
                                    String message = property.get("id").asText();
                                    propertiesMap.put(message, interval);
                                }
                            }
                        }
                    }
                }
            }
        } catch (JsonProcessingException e) {
            LOG.error("Issue parsing JSON: ", e);
        }
        startScript();
    }

    private static void startScript() {
        for (Map.Entry<String, Integer> entry : propertiesMap.entrySet()) {
            final Runnable runScript = new Runnable() {
                public void run() {
                    if(entry.getKey().equals("cpu_usage")) {
                        LOG.info("cpu_usage");
                    }
                    sendMessagesToClients(entry.getKey());
                }
            };
            ScheduledExecutorService executor = Executors.newScheduledThreadPool(1);
            executor.scheduleAtFixedRate(runScript, 0, entry.getValue(), TimeUnit.MILLISECONDS);
        }
    }

    private static void sendMessagesToClients(final String message) {
        try {
            String json = runServerScript(message);
            Iterator<Session> iterator = sessions.iterator();
            while (iterator.hasNext()) {
                Session session = iterator.next();
                if (session.isOpen()) {
                    synchronized (session) {
                        session.getBasicRemote().sendObject(json);
                    }
                } else {
                    sessions.remove(session);
                }
            }
        } catch (Exception e) {
            LOG.error("Error sending message: ", e);
        }
    }

    @OnOpen
    public void open(final Session session) {
        sessions.add(session);
        LOG.info("Opened websocket connection: {} - {}", sessions.size(), session.getId());

        try {
            String json = runServerScript("groups");
            session.getBasicRemote().sendObject(json);
            for (Map.Entry<String, Integer> entry : propertiesMap.entrySet()) {
                json = runServerScript(entry.getKey());
                session.getBasicRemote().sendObject(json);
            }
        } catch (IOException | EncodeException e) {
            LOG.error("Issue sending group json: ", e);
        }
    }

    @OnClose
    public void close(final Session session) {
        sessions.remove(session);
        LOG.info("Closed websocket connection: {} - {}", sessions.size(), session.getId());
    }

    @OnMessage
    public void handleMessage(final String message, final Session session) {
        try {
            long startTime = System.nanoTime();
            LOG.info("Begin - " + message);
            final String result = runServerScript(message);
            long elapsedTime = System.nanoTime() - startTime;
            LOG.info("End - " + message + " | Elapsed seconds : " + ((double) elapsedTime / 1_000_000_000.0));
            session.getBasicRemote().sendText(result);
        } catch (IOException e) {
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
        } catch (IOException e) {
            LOG.error("Issue copying file to temp directory: ", e);
        }
        return "";
    }

    private static final String runServerScript(String bashFunction) {
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
        } catch (Exception e) {
            LOG.error("Issue running script: ", e);
        }

        if (process != null) {
            try (InputStream is = process.getInputStream(); ByteArrayOutputStream baos = new ByteArrayOutputStream();) {
                byte[] buffer = new byte[1024];
                int length;
                while ((length = is.read(buffer)) != -1) {
                    baos.write(buffer, 0, length);
                }
                retVal = baos.toString(StandardCharsets.UTF_8.name());
            } catch (Exception e) {
                LOG.error("Issue retrieving script output: ", e);
            }
        }
        return retVal;
    }
}
