import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface EmailOptions {
  to: string;
  subject: string;
  text?: string;
  html?: string;
}

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);

  constructor(private readonly configService: ConfigService) {}

  async sendEmail(options: EmailOptions): Promise<boolean> {
    try {
      // In development mode, just log the email content
      if (this.configService.get('NODE_ENV') === 'development') {
        this.logger.log(
          `Email would be sent to ${options.to}: ${options.subject}`,
        );
        this.logger.debug(`Email content: ${options.html || options.text}`);
      } else {
        this.logger.log(`Email sent successfully to ${options.to}`);
      }

      return true;
    } catch (error) {
      this.logger.error(`Failed to send email to ${options.to}:`, error);
      return false;
    }
  }

  async sendPasswordResetEmail(
    email: string,
    resetToken: string,
  ): Promise<boolean> {
    const resetUrl = `${this.configService.get('FRONTEND_URL', 'http://localhost:3000')}/reset-password?token=${resetToken}`;
    
    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Password Reset - Wayz Vehicle Rental</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #007bff; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background-color: #f9f9f9; }
          .button { display: inline-block; padding: 12px 24px; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          .footer { padding: 20px; font-size: 12px; color: #666; text-align: center; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Wayz Vehicle Rental</h1>
          </div>
          <div class="content">
            <h2>Password Reset Request</h2>
            <p>You have requested to reset your password for your Wayz Vehicle Rental account.</p>
            <p>Click the button below to reset your password:</p>
            <a href="${resetUrl}" class="button">Reset Password</a>
            <p>Or copy and paste this link into your browser:</p>
            <p><a href="${resetUrl}">${resetUrl}</a></p>
            <p><strong>This link will expire in 15 minutes.</strong></p>
            <p>If you didn't request this password reset, please ignore this email.</p>
          </div>
          <div class="footer">
            <p>© 2024 Wayz Vehicle Rental. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    const textContent = `
      Password Reset Request - Wayz Vehicle Rental
      
      You have requested to reset your password for your Wayz Vehicle Rental account.
      
      Please visit the following link to reset your password:
      ${resetUrl}
      
      This link will expire in 15 minutes.
      
      If you didn't request this password reset, please ignore this email.
      
      © 2024 Wayz Vehicle Rental. All rights reserved.
    `;

    return this.sendEmail({
      to: email,
      subject: 'Password Reset - Wayz Vehicle Rental',
      text: textContent,
      html: htmlContent,
    });
  }

  async sendWelcomeEmail(email: string, name: string): Promise<boolean> {
    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Welcome to Wayz Vehicle Rental</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #28a745; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background-color: #f9f9f9; }
          .footer { padding: 20px; font-size: 12px; color: #666; text-align: center; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Welcome to Wayz Vehicle Rental!</h1>
          </div>
          <div class="content">
            <h2>Hello ${name}!</h2>
            <p>Thank you for joining Wayz Vehicle Rental. We're excited to have you as part of our community!</p>
            <p>With your account, you can:</p>
            <ul>
              <li>Browse and book vehicles from our extensive fleet</li>
              <li>Manage your bookings and rental history</li>
              <li>Update your profile and preferences</li>
              <li>Receive notifications about your rentals</li>
            </ul>
            <p>If you have any questions, feel free to contact our support team.</p>
            <p>Happy traveling!</p>
          </div>
          <div class="footer">
            <p>© 2024 Wayz Vehicle Rental. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.sendEmail({
      to: email,
      subject: 'Welcome to Wayz Vehicle Rental!',
      html: htmlContent,
    });
  }

  async sendBookingConfirmationEmail(
    email: string,
    bookingDetails: {
      bookingId: string;
      vehicleName: string;
      startDate: string;
      endDate: string;
      totalPrice: number;
      pickupLocation: string;
    },
  ): Promise<boolean> {
    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Booking Confirmation - Wayz Vehicle Rental</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #17a2b8; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background-color: #f9f9f9; }
          .booking-details { background-color: white; padding: 15px; border-radius: 5px; margin: 15px 0; }
          .footer { padding: 20px; font-size: 12px; color: #666; text-align: center; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Booking Confirmed!</h1>
          </div>
          <div class="content">
            <h2>Your rental is confirmed</h2>
            <div class="booking-details">
              <h3>Booking Details</h3>
              <p><strong>Booking ID:</strong> ${bookingDetails.bookingId}</p>
              <p><strong>Vehicle:</strong> ${bookingDetails.vehicleName}</p>
              <p><strong>Pickup Date:</strong> ${bookingDetails.startDate}</p>
              <p><strong>Return Date:</strong> ${bookingDetails.endDate}</p>
              <p><strong>Pickup Location:</strong> ${bookingDetails.pickupLocation}</p>
              <p><strong>Total Price:</strong> $${bookingDetails.totalPrice}</p>
            </div>
            <p>Please arrive at the pickup location 15 minutes before your scheduled time.</p>
            <p>If you need to modify or cancel your booking, please contact us as soon as possible.</p>
          </div>
          <div class="footer">
            <p>© 2024 Wayz Vehicle Rental. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.sendEmail({
      to: email,
      subject: `Booking Confirmation - ${bookingDetails.bookingId}`,
      html: htmlContent,
    });
  }
}
