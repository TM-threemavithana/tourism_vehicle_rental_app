import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseService implements OnModuleInit {
  private app: admin.app.App;

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    const privateKey = this.configService
      .get('FIREBASE_PRIVATE_KEY')
      ?.replace(/\\n/g, '\n');

    if (!privateKey || !this.configService.get('FIREBASE_PROJECT_ID')) {
      console.warn('Firebase Admin SDK not configured. Dual-write disabled.');
      return;
    }

    try {
      this.app = admin.initializeApp({
        credential: admin.credential.cert({
          projectId: this.configService.get('FIREBASE_PROJECT_ID'),
          clientEmail: this.configService.get('FIREBASE_CLIENT_EMAIL'),
          privateKey: privateKey,
        }),
        databaseURL: this.configService.get('FIREBASE_DATABASE_URL'),
      });

      console.log('✅ Firebase Admin SDK initialized successfully');
    } catch (error) {
      console.error(
        '❌ Firebase Admin SDK initialization failed:',
        error.message,
      );
    }
  }

  // Get Firestore instance
  get firestore() {
    return this.app?.firestore();
  }

  // Get Auth instance
  get auth() {
    return this.app?.auth();
  }

  // Get Storage instance
  get storage() {
    return this.app?.storage();
  }

  // Get Real-time Database instance
  get database() {
    return this.app?.database();
  }

  // Check if Firebase is configured and initialized
  get isInitialized(): boolean {
    return !!this.app;
  }

  // Helper method to create a Firestore document
  async createFirestoreDocument(collection: string, data: any, docId?: string) {
    if (!this.isInitialized) {
      console.warn('Firebase not initialized. Skipping Firestore write.');
      return null;
    }

    try {
      const docRef = docId
        ? this.firestore.collection(collection).doc(docId)
        : this.firestore.collection(collection).doc();

      await docRef.set({
        ...data,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (error) {
      console.error(
        `Failed to create Firestore document in ${collection}:`,
        error,
      );
      throw error;
    }
  }

  // Helper method to update a Firestore document
  async updateFirestoreDocument(collection: string, docId: string, data: any) {
    if (!this.isInitialized) {
      console.warn('Firebase not initialized. Skipping Firestore update.');
      return;
    }

    try {
      const docRef = this.firestore.collection(collection).doc(docId);
      await docRef.update({
        ...data,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      console.error(
        `Failed to update Firestore document in ${collection}:`,
        error,
      );
      throw error;
    }
  }

  // Helper method to delete a Firestore document
  async deleteFirestoreDocument(collection: string, docId: string) {
    if (!this.isInitialized) {
      console.warn('Firebase not initialized. Skipping Firestore delete.');
      return;
    }

    try {
      await this.firestore.collection(collection).doc(docId).delete();
    } catch (error) {
      console.error(
        `Failed to delete Firestore document in ${collection}:`,
        error,
      );
      throw error;
    }
  }

  // Verify Firebase token (for user migration)
  async verifyIdToken(token: string) {
    if (!this.isInitialized) {
      throw new Error('Firebase not initialized');
    }

    try {
      const decodedToken = await this.auth.verifyIdToken(token);
      return decodedToken;
    } catch (error) {
      console.error('Failed to verify Firebase token:', error);
      throw error;
    }
  }
}
