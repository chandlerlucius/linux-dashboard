package com.utils.dashboard;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {

    private static final long serialVersionUID = -4796947973944182251L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Stringify dashboard.html for response
        String output = "";
        try (InputStream indexIS = this.getClass().getResourceAsStream("/static/html/dashboard.html");) {
            ByteArrayOutputStream result = new ByteArrayOutputStream();
            byte[] buffer = new byte[1024];
            int length;
            while ((length = indexIS.read(buffer)) != -1) {
                result.write(buffer, 0, length);
            }
            output = result.toString(StandardCharsets.UTF_8.name());
        } catch (Exception e) {
            e.printStackTrace();
        }

        // Setup response for HTML output
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        out.println(output);
    }
}