import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Department from '../models/Department';

dotenv.config();

const MONGO_URI = process.env.MONGO_URI as string;

async function run() {
  if (!MONGO_URI) {
    console.error('MONGO_URI is not defined in .env');
    process.exit(1);
  }

  try {
    await mongoose.connect(MONGO_URI);
    console.log('Connected to MongoDB.');

    // Note: In production, do not wipe databases via this script.
    // Ensure the department exists
    let dept = await Department.findOne({ code: 'MCA' });
    if (!dept) {
      console.log('Creating Master MCA Department...');
      dept = await Department.create({
        name: 'Master of Computer Applications',
        code: 'MCA',
        settings: {
          allowAlumniRegistration: true,
          requireHodApprovalForAlumni: true,
          defaultBatchValidityYears: 3,
        }
      });
      console.log('Department created.');
    } else {
      console.log('Department MCA already exists.');
    }

    console.log('Initialization Complete.');
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

run();
