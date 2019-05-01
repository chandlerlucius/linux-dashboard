package com.utils.dashboard;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import javax.websocket.OnClose;
import javax.websocket.OnError;
import javax.websocket.OnMessage;
import javax.websocket.OnOpen;
import javax.websocket.Session;
import javax.websocket.server.ServerEndpoint;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@ServerEndpoint(value = "/websocket")
public class DashboardWebSocket {

    private static final Logger LOG = LoggerFactory.getLogger(DashboardWebSocket.class);

    Set<Session> sessionSet = new HashSet<>();
    ScheduledExecutorService ses = Executors.newSingleThreadScheduledExecutor();

    public DashboardWebSocket() {
        copyExecScriptToTempDir("/sh/ServerStats.sh", "ServerStats.sh");
        startSocketTransmission();
    }

    public DashboardWebSocket(final boolean withoutArguments) {
    }

    @OnOpen
    public void open(final Session session) {
        sessionSet.add(session);
    }

    @OnClose
    public void close(final Session session) {
        sessionSet.remove(session);
        if (sessionSet.isEmpty()) {
            ses.shutdownNow();
        }
    }

    @OnMessage
    public void handleMessage(final String message, final Session session) {
        LOG.info("Message from websocket connection: ", message);
    }

    /**
    * Log error if one occurs
    *
    * @author clucius
    */
    @OnError
    public void onError(final Throwable e) {
        LOG.error("Issue with websocket connection: ", e);
    }

    public File copyExecScriptToTempDir(final String inputFilePath, final String outputFileName) {
        try (InputStream is = this.getClass().getResourceAsStream(inputFilePath)) {
            final String tempDirectory = System.getProperty("java.io.tmpdir");
            final File tempFile = new File(tempDirectory + "/" + outputFileName);
            Files.copy(is, tempFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
            tempFile.setExecutable(true);
            return tempFile;
        } catch (Exception e) {
            LOG.error("Issue copying file to temp directory: ", e);
        }
        return new File("");
    }

    private void startSocketTransmission() {
        ses.scheduleWithFixedDelay(new Runnable() {
            @Override
            public void run() {
                final String message = runServerScript();
                // System.out.println(message);
                sessionSet.forEach(session -> {
                    synchronized (session) {
                        try {
                            session.getBasicRemote().sendText(message);
                        } catch (Exception e) {
                            LOG.error("Issue sending remote message: ", e);
                        }
                    }
                });
            }
        }, 0, 1, TimeUnit.SECONDS);
    }

    private static String runServerScript() {
        String results = "";
        try {
            // Run server stats script
            final String tempDirectory = System.getProperty("java.io.tmpdir");
            final File tempFile = new File(tempDirectory + "/ServerStats.sh");
            final ProcessBuilder processBuilder = new ProcessBuilder("./" + tempFile.getName());
            processBuilder.directory(new File(tempDirectory));
            final Process process = processBuilder.start();
            process.waitFor();

            // Get output from script
            try (InputStream inputStream = process.getInputStream()) {
                final ByteArrayOutputStream result = new ByteArrayOutputStream();
                final byte[] buffer = new byte[1024];
                int length;
                while ((length = inputStream.read(buffer)) != -1) {
                    result.write(buffer, 0, length);
                }
                results = result.toString(StandardCharsets.UTF_8.name());
            } catch (Exception e) {
                LOG.error("Issue getting output from script: ", e);
            }
        } catch (Exception e) {
            LOG.error("Issue running script: ", e);
        }
        return results;
    }
}