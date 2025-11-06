
#!/usr/bin/env python3
"""
Email Alert Script
Sends email notifications for server monitoring alerts
"""

import smtplib
import argparse
import os
import sys
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
import socket

# Configuration from environment variables
SMTP_SERVER = os.getenv('SMTP_SERVER', 'smtp.gmail.com')
SMTP_PORT = int(os.getenv('SMTP_PORT', '587'))
SMTP_USER = os.getenv('SMTP_USER', '')
SMTP_PASSWORD = os.getenv('SMTP_PASSWORD', '')
FROM_EMAIL = os.getenv('FROM_EMAIL', SMTP_USER)


class EmailAlert:
    """Handle email alert notifications"""
    
    def __init__(self, smtp_server=SMTP_SERVER, smtp_port=SMTP_PORT,
                 smtp_user=SMTP_USER, smtp_password=SMTP_PASSWORD):
        self.smtp_server = smtp_server
        self.smtp_port = smtp_port
        self.smtp_user = smtp_user
        self.smtp_password = smtp_password
        self.hostname = socket.gethostname()
        
    def create_html_message(self, subject, message):
        """Create HTML formatted email"""
        html = f"""
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; }}
                .header {{ background-color: #d32f2f; color: white; padding: 20px; }}
                .content {{ padding: 20px; }}
                .footer {{ background-color: #f5f5f5; padding: 10px; font-size: 12px; }}
                .info {{ background-color: #fff3cd; padding: 10px; border-left: 4px solid #ffc107; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h2>⚠️ Server Alert</h2>
            </div>
            <div class="content">
                <h3>{subject}</h3>
                <div class="info">
                    <p><strong>Message:</strong> {message}</p>
                    <p><strong>Server:</strong> {self.hostname}</p>
                    <p><strong>Time:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
                </div>
            </div>
            <div class="footer">
                <p>This is an automated alert from your server monitoring system.</p>
            </div>
        </body>
        </html>
        """
        return html
    
    def send_email(self, to_email, subject, message, html=True):
        """Send email alert"""
        try:
            # Create message
            msg = MIMEMultipart('alternative')
            msg['Subject'] = f"[{self.hostname}] {subject}"
            msg['From'] = FROM_EMAIL
            msg['To'] = to_email
            
            # Add plain text version
            text_part = MIMEText(f"{subject}\n\n{message}\n\nServer: {self.hostname}\nTime: {datetime.now()}", 'plain')
            msg.attach(text_part)
            
            # Add HTML version if requested
            if html:
                html_content = self.create_html_message(subject, message)
                html_part = MIMEText(html_content, 'html')
                msg.attach(html_part)
            
            # Connect and send
            print(f"Connecting to {self.smtp_server}:{self.smtp_port}...")
            
            server = smtplib.SMTP(self.smtp_server, self.smtp_port)
            server.starttls()
            
            if self.smtp_user and self.smtp_password:
                server.login(self.smtp_user, self.smtp_password)
            
            server.send_message(msg)
            server.quit()
            
            print(f"✓ Alert email sent to {to_email}")
            return True
            
        except smtplib.SMTPAuthenticationError:
            print("✗ SMTP Authentication failed. Check your credentials.")
            return False
        except smtplib.SMTPException as e:
            print(f"✗ SMTP error: {e}")
            return False
        except Exception as e:
            print(f"✗ Failed to send email: {e}")
            return False


def main():
    parser = argparse.ArgumentParser(description='Send email alerts')
    parser.add_argument('--to', required=True, help='Recipient email address')
    parser.add_argument('--subject', required=True, help='Email subject')
    parser.add_argument('--message', required=True, help='Email message')
    parser.add_argument('--no-html', action='store_true', help='Send plain text only')
    
    args = parser.parse_args()
    
    # Check if credentials are configured
    if not SMTP_USER or not SMTP_PASSWORD:
        print("Warning: SMTP credentials not configured. Set SMTP_USER and SMTP_PASSWORD environment variables.")
        sys.exit(1)
    
    # Send email
    alert = EmailAlert()
    success = alert.send_email(
        to_email=args.to,
        subject=args.subject,
        message=args.message,
        html=not args.no_html
    )
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
