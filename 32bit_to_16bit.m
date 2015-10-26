petdir = ('Z:\Hopkins-data\GD_(NA_00021615)\Processed_Images\PET_Data\!Data\70min');
Spetdir = ('Z:\Hopkins-data\GD_(NA_00021615)\Processed_Images\PET_Data\!Data');

pet_struct = dir([petdir '\*.img']);
Spet_struct = dir([Spetdir '\h*.img']);

sizepet = size(pet_struct,1);

sizeSpet = size(Spet_struct,1);

for ii=1:sizepet,
    pet_name = spm_vol([petdir '\' pet_struct(ii).name ',1']);
    Spet_name = spm_vol([Spetdir '\h' pet_struct(ii).name ',1']);
    read_pet = spm_vol(pet_name);
    read_Spet = spm_vol(Spet_name);
    conv_pet = spm_read_vols(read_pet);
    read_pet.dt = read_Spet.dt;
    read_pet.pinfo = read_Spet.pinfo;
    read_pet.fname = [petdir '\dt' pet_struct(ii).name];
    spm_write_vol(read_pet,conv_pet);
end