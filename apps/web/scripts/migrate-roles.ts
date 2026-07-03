import dotenv from 'dotenv';
import mongoose from 'mongoose';
import UserAccount from '../models/UserAccount';

dotenv.config({ path: '.env.local' });
dotenv.config();

const MONGO_URI = process.env.MONGO_URI;

if (!MONGO_URI) {
  console.error('MONGO_URI is missing');
  process.exit(1);
}

async function migrateRoles() {
  await mongoose.connect(MONGO_URI!);

  console.log('Migrating Alumni to Student...');
  const alumniUpdate = await UserAccount.updateMany(
    { role: 'alumni' as any }, // 'any' because alumni was removed from the enum
    { $set: { role: 'student', accountType: 'alumni' } }
  );
  console.log(`Updated ${alumniUpdate.modifiedCount} alumni.`);

  console.log('Migrating Maintainer to Admin...');
  const adminUpdate = await UserAccount.updateMany(
    { role: 'maintainer' as any },
    { $set: { role: 'admin' } }
  );
  console.log(`Updated ${adminUpdate.modifiedCount} maintainers.`);

  console.log('Migrating HOD to Faculty...');
  const hodUpdate = await UserAccount.updateMany(
    { role: 'hod' as any },
    { $set: { role: 'faculty' } }
  );
  console.log(`Updated ${hodUpdate.modifiedCount} HODs.`);

  mongoose.connection.close();
}

migrateRoles().catch(console.error);
