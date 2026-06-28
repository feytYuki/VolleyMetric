<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String username = (String) session.getAttribute("resetOrganizerUsername");
    if (username == null) {
        response.sendRedirect("OrganizerForgotPassword.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Reset Password - VolleyMetric Organizer</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                min-height: 100vh;
                color: #333;
                background-color: #f5f5f5;
            }
            .header {
                background-color: #1a1a2e;
                color: #fff;
                padding: 1rem 2rem;
            }
            .header .container {
                display: flex;
                align-items: center;
            }
            .logo {
                display: flex;
                align-items: center;
                gap: 0.75rem;
            }
            .logo-link {
                display: flex;
                align-items: center;
                gap: 0.5rem;
                text-decoration: none;
                color: inherit;
            }
            .logo-icon {
                font-size: 1.5rem;
                font-weight: bold;
            }
            .logo-text {
                font-size: 1.5rem;
                font-weight: bold;
            }
            .auth-section {
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: calc(100vh - 70px);
                padding: 2rem;
            }
            .auth-container {
                width: 100%;
                max-width: 420px;
            }
            .auth-card {
                background-color: #fff;
                border-radius: 10px;
                padding: 2.5rem;
                box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            }
            .auth-header {
                text-align: center;
                margin-bottom: 2rem;
            }
            .auth-icon {
                font-size: 3rem;
                margin-bottom: 0.75rem;
            }
            .auth-title {
                font-size: 1.8rem;
                color: #1a1a2e;
                margin-bottom: 0.5rem;
            }
            .auth-subtitle {
                color: #666;
                font-size: 0.95rem;
            }
            .user-badge {
                background-color: #f0f4ff;
                border: 1px solid #d0d9ff;
                border-radius: 5px;
                padding: 0.6rem 1rem;
                margin-bottom: 1.5rem;
                font-size: 0.9rem;
                color: #1a1a2e;
                text-align: center;
            }
            .form-group {
                display: flex;
                flex-direction: column;
                gap: 0.5rem;
                margin-bottom: 1.25rem;
            }
            .form-label {
                font-weight: 600;
                color: #333;
                font-size: 0.95rem;
            }
            .password-wrapper {
                position: relative;
            }
            .password-wrapper .form-input {
                padding-right: 2.8rem;
                width: 100%;
                box-sizing: border-box;
            }
            .toggle-password {
                position: absolute;
                right: 0.8rem;
                top: 50%;
                transform: translateY(-50%);
                background: none;
                border: none;
                cursor: pointer;
                padding: 0;
                color: #888;
                display: flex;
                align-items: center;
            }
            .toggle-password:hover {
                color: #555;
            }
            .form-input {
                padding: 0.8rem 1rem;
                border: 2px solid #e0e0e0;
                border-radius: 5px;
                font-size: 1rem;
                transition: all 0.3s;
                font-family: inherit;
            }
            .form-input:focus {
                outline: none;
                border-color: #667eea;
                box-shadow: 0 0 0 3px rgba(102,126,234,0.1);
            }
            .btn {
                padding: 0.8rem 1.5rem;
                border-radius: 5px;
                font-weight: 600;
                cursor: pointer;
                border: none;
                font-size: 1rem;
                transition: all 0.3s;
                width: 100%;
                margin-top: 0.5rem;
            }
            .btn-primary {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: #fff;
            }
            .btn-primary:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(102,126,234,0.4);
            }
            .back-link {
                text-align: center;
                margin-top: 1.5rem;
            }
            .back-link a {
                color: #667eea;
                text-decoration: none;
                font-size: 0.9rem;
                font-weight: 500;
            }
            .back-link a:hover {
                text-decoration: underline;
            }
            .alert {
                padding: 0.9rem 1rem;
                border-radius: 5px;
                margin-bottom: 1.5rem;
                font-size: 0.9rem;
            }
            .alert-error {
                background-color: #ffe0e0;
                color: #c0392b;
                border: 1px solid #f5c6cb;
            }
        </style>
    </head>
    <body>
        <header class="header">
            <div class="container">
                <div class="logo">
                    <div style="width:40px;height:40px;overflow:hidden;background:white;border:2px solid red;">
                        <img src="umtlogo.png" alt="UMT Logo" style="width:100%;height:100%;object-fit:contain;" onerror="this.style.display='none'">
                    </div>
                    <a href="Homepage.jsp" class="logo-link">
                        <span class="logo-icon">🏐</span>
                        <span class="logo-text">VolleyMetric</span>
                    </a>
                </div>
            </div>
        </header>

        <section class="auth-section">
            <div class="auth-container">
                <div class="auth-card">
                    <div class="auth-header">
                        <div class="auth-icon">🔒</div>
                        <h1 class="auth-title">Reset Password</h1>
                        <p class="auth-subtitle">Create a new password for your organizer account</p>
                    </div>

                    <div class="user-badge">👤 Resetting for: <strong><%= username%></strong></div>

                    <% String error = (String) request.getAttribute("error"); %>
                    <% if (error != null) {%>
                    <div class="alert alert-error"><%= error%></div>
                    <% }%>

                    <form action="PasswordResetServlet" method="POST">
                        <input type="hidden" name="action" value="reset">
                        <input type="hidden" name="role" value="organizer">
                        <div class="form-group">
                            <label class="form-label">New Password</label>
                            <div class="password-wrapper">
                                <input type="password" name="newPassword" class="form-input"
                                       placeholder="Enter new password" required minlength="6">
                                <button type="button" class="toggle-password" onclick="togglePassword(this)" aria-label="Toggle password visibility">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="eye-icon"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                                </button>
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Confirm New Password</label>
                            <div class="password-wrapper">
                                <input type="password" name="confirmPassword" class="form-input"
                                       placeholder="Re-enter new password" required minlength="6">
                                <button type="button" class="toggle-password" onclick="togglePassword(this)" aria-label="Toggle password visibility">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="eye-icon"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                                </button>
                            </div>
                        </div>
                        <button type="submit" class="btn btn-primary">Reset Password</button>
                    </form>

                    <div class="back-link">
                        <a href="OrganizerForgotPassword.jsp">← Back</a>
                    </div>
                </div>
            </div>
        </section>

        <script>
            function togglePassword(btnEl) {
                var input = btnEl.previousElementSibling;
                var isText = input.type === 'text';
                input.type = isText ? 'password' : 'text';
                btnEl.querySelector('.eye-icon').innerHTML = isText
                        ? '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle>'
                        : '<path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line>';
            }
        </script>
    </body>
</html>
