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

@ServerEndpoint(value="/websocket")
public class DashboardWebSocket {

    Set<Session> sessionSet = new HashSet<>();
    ScheduledExecutorService ses = Executors.newSingleThreadScheduledExecutor();

    public DashboardWebSocket() {
        try (InputStream serverStatsIS = this.getClass().getResourceAsStream("/static/sh/ServerStats.sh");
                InputStream jqLinuxIS = this.getClass().getResourceAsStream("/static/sh/jq-linux64");) {

            // Write server stats script to temp directory
            String tempDirectory = System.getProperty("java.io.tmpdir");
            File serverStatsTempFile = new File(tempDirectory + "/ServerStats.sh");
            Files.copy(serverStatsIS, serverStatsTempFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
            serverStatsTempFile.setExecutable(true);
        } catch (Exception e) {
            e.printStackTrace();
        }
        startSocketTransmission();
    }

    @OnOpen
    public void open(Session session) {
        sessionSet.add(session);
    }

    @OnClose
    public void close(Session session) {
        sessionSet.remove(session);
        if(sessionSet.isEmpty()) {
            ses.shutdownNow();
        }
    }
    
    @OnMessage
    public void handleMessage(String message, Session session) {
        System.out.println("message");
    }

    @OnError
    public void onError(Throwable error) {
        System.err.println(error);
    }

    private void startSocketTransmission() {
        ses.scheduleWithFixedDelay(new Runnable() {
            @Override
            public void run() {
                String message = runServerScript();
                System.out.println(message);
                sessionSet.forEach(session -> {
                    synchronized (session) {
                        try {
                            session.getBasicRemote().sendText(message);
                        } catch (Exception e) {
                            e.printStackTrace();
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
            String tempDirectory = System.getProperty("java.io.tmpdir");
            File serverStatsTempFile = new File(tempDirectory + "/ServerStats.sh");
            ProcessBuilder processBuilder = new ProcessBuilder("./" + serverStatsTempFile.getName());
            processBuilder.directory(new File(tempDirectory));
            Process process = processBuilder.start();
            process.waitFor();

            // Get output from script
            if (process.getInputStream() != null) {
                try (InputStream is = process.getInputStream()) {
                    ByteArrayOutputStream result = new ByteArrayOutputStream();
                    byte[] buffer = new byte[1024];
                    int length;
                    while ((length = is.read(buffer)) != -1) {
                        result.write(buffer, 0, length);
                    }
                    results = result.toString(StandardCharsets.UTF_8);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return results;
    }
}