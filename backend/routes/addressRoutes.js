import express from 'express';
import { getUserAddresses, addUserAddress, updateUserAddress, deleteUserAddress, setDefaultUserAddress } from '../controllers/addressController.js';

const router = express.Router();

router.get('/', getUserAddresses);
router.post('/', addUserAddress);
router.put('/:addressId', updateUserAddress);
router.delete('/:addressId', deleteUserAddress);
router.post('/:addressId/default', setDefaultUserAddress);

export default router;