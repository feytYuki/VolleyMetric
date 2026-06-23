<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Organizer Registration - VolleyMetric</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f5f5f5;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
        }

        /* Header Styles */
        .header {
            background-color: #1a1a2e;
            color: #fff;
            padding: 1rem 0;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }

        .logo {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 1.5rem;
            font-weight: bold;
        }

        .logo-link {
            display: flex;
            align-items: center;
            gap: 10px;
            text-decoration: none;
            color: inherit;
        }

        .logo-icon {
            font-size: 2rem;
        }

        .logo-text {
            color: #fff;
        }

        /* Auth Section - Centered */
        .auth-section {
            flex: 1;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 3rem 20px;
        }

        .auth-container {
            width: 100%;
            max-width: 500px;
        }

        .auth-card {
            background-color: #fff;
            border-radius: 10px;
            padding: 3rem;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
        }

        .auth-header {
            text-align: center;
            margin-bottom: 2rem;
        }

        .auth-title {
            font-size: 2rem;
            color: #1a1a2e;
            margin-bottom: 0.5rem;
        }

        .auth-subtitle {
            color: #666;
            font-size: 1rem;
        }

        .organizer-badge {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            padding: 0.5rem 1rem;
            border-radius: 20px;
            font-size: 0.9rem;
            font-weight: 600;
            margin-bottom: 1rem;
        }

        .auth-form {
            display: flex;
            flex-direction: column;
            gap: 1.5rem;
        }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
        }

        .form-label {
            font-weight: 600;
            color: #333;
            font-size: 0.95rem;
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
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }

        .btn {
            padding: 0.8rem 1.5rem;
            text-decoration: none;
            border-radius: 5px;
            transition: all 0.3s;
            display: inline-block;
            font-weight: 600;
            text-align: center;
            border: none;
            cursor: pointer;
            font-size: 1rem;
        }

        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
        }

        .btn-full {
            width: 100%;
        }

        .auth-footer {
            margin-top: 1.5rem;
            text-align: center;
        }

        .auth-text {
            color: #666;
        }

        .auth-link {
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
        }

        .auth-link:hover {
            color: #5568d3;
            text-decoration: underline;
        }

        /* Alert Messages */
        .alert {
            padding: 1rem;
            border-radius: 5px;
            margin-bottom: 1.5rem;
            font-size: 0.95rem;
        }

        .alert-error {
            background-color: #fee;
            border: 1px solid #fcc;
            color: #c33;
        }

        .alert-success {
            background-color: #efe;
            border: 1px solid #cfc;
            color: #3c3;
        }

        /* Footer Styles */
        .footer {
            background-color: #1a1a2e;
            color: #fff;
            padding: 1.5rem 0;
            margin-top: auto;
        }

        .footer-simple {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 1rem;
        }

        .footer-links {
            display: flex;
            gap: 1.5rem;
        }

        .footer-links a {
            color: #aaa;
            text-decoration: none;
            transition: color 0.3s;
        }

        .footer-links a:hover {
            color: #ff6b6b;
        }

        /* Responsive Design */
        @media (max-width: 768px) {
            .auth-card {
                padding: 2rem;
            }

            .auth-title {
                font-size: 1.5rem;
            }

            .footer-simple {
                flex-direction: column;
                text-align: center;
            }
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
        .toggle-password:hover { color: #555; }

    </style>
</head>
<body>
    <!-- Header -->
    <header class="header">
        <div class="container">
            <div class="logo">
                <div style="width: 40px; height: 40px; overflow: hidden; background: white; border: 2px solid red;">
                    <img src="umtlogo.png" alt="UMT Logo" class="umt-logo"
                         style="width: 100%; height: 100%; object-fit: contain;"
                         onerror="console.log('Image failed to load'); this.style.display='none';">
                </div>
                <a href="Homepage.jsp" class="logo-link">
                    <span class="logo-icon">🏐</span>
                    <span class="logo-text">VolleyMetric</span>
                </a>
            </div>
        </div>
    </header>

    <!-- Registration Form Section -->
    <section class="auth-section">
        <div class="auth-container">
            <div class="auth-card">
                <div class="auth-header">
                    <div class="organizer-badge">🎯 Organizer Account</div>
                    <h1 class="auth-title">Create Organizer Account</h1>
                    <p class="auth-subtitle">Register as an organizer to create and manage tournaments</p>
                </div>

                <!-- Error Message Display -->
                <% 
                    String errorMessage = (String) request.getAttribute("errorMessage");
                    if (errorMessage != null) {
                %>
                    <div class="alert alert-error">
                        <%= errorMessage %>
                    </div>
                <% } %>

                <form action="OrganizerRegister" method="POST" class="auth-form">
                    <div class="form-group">
                        <label for="fullname" class="form-label">Full Name</label>
                        <input 
                            type="text" 
                            id="fullname" 
                            name="fullname" 
                            class="form-input" 
                            placeholder="Enter your full name"
                            value="<%= request.getParameter("fullname") != null ? request.getParameter("fullname") : "" %>"
                            required
                        />
                    </div>

                    <div class="form-group">
                        <label for="username" class="form-label">Username</label>
                        <input 
                            type="text" 
                            id="username" 
                            name="username" 
                            class="form-input" 
                            placeholder="Choose a username"
                            value="<%= request.getParameter("username") != null ? request.getParameter("username") : "" %>"
                            required
                        />
                    </div>

                    <div class="form-group">
                        <label for="email" class="form-label">Email Address</label>
                        <input 
                            type="email" 
                            id="email" 
                            name="email" 
                            class="form-input" 
                            placeholder="Enter your email"
                            value="<%= request.getParameter("email") != null ? request.getParameter("email") : "" %>"
                            required
                        />
                    </div>

                    <div class="form-group">
                        <label for="phone" class="form-label">Phone Number</label>
                        <input 
                            type="tel" 
                            id="phone" 
                            name="phone" 
                            class="form-input" 
                            placeholder="Enter your phone number"
                            value="<%= request.getParameter("phone") != null ? request.getParameter("phone") : "" %>"
                            required
                        />
                    </div>

                    <div class="form-group">
                        <label for="password" class="form-label">Password</label>
                        <div class="password-wrapper">
                            <input 
                            type="password" 
                            id="password" 
                            name="password" 
                            class="form-input" 
                            placeholder="Create a password"
                            required
                        />
                            <button type="button" class="toggle-password" onclick="togglePassword(this)" aria-label="Toggle password visibility"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="eye-icon"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg></button>
                        </div>
                    </div>

                    <div class="form-group">
                        <label for="confirmPassword" class="form-label">Confirm Password</label>
                        <div class="password-wrapper">
                            <input 
                            type="password" 
                            id="confirmPassword" 
                            name="confirmPassword" 
                            class="form-input" 
                            placeholder="Re-enter your password"
                            required
                        />
                            <button type="button" class="toggle-password" onclick="togglePassword(this)" aria-label="Toggle password visibility"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="eye-icon"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path><circle cx="12" cy="12" r="3"></circle></svg></button>
                        </div>
                    </div>

                    <button type="submit" class="btn btn-primary btn-full">
                        Register as Organizer
                    </button>
                </form>

                <div class="auth-footer">
                    <p class="auth-text">
                        Already have an account? 
                        <a href="OrganizerLogin.jsp" class="auth-link">Login here</a>
                    </p>
                    <p class="auth-text" style="margin-top: 1rem;">
                        Register as a regular user? 
                        <a href="Register.jsp" class="auth-link">User Registration</a>
                    </p>
                </div>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer class="footer">
        <div class="container">
            <div class="footer-simple">
                <p>&copy; <%= new java.util.Date().getYear() + 1900 %> VolleyMetric. All rights reserved.</p>
                <div class="footer-links">
                    <a href="#privacy">Privacy Policy</a>
                    <a href="#terms">Terms of Service</a>
                </div>
            </div>
        </div>
    </footer>

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