/*

Cleaning Data in SQL Queries

*/

select*
from PortfolioProject..NashvilleHousing



--standardise date format

select SaleDateconverted, convert(date, saledate)
from PortfolioProject..NashvilleHousing

update NashvilleHousing
set SaleDate = convert(date, saledate)

alter table nashvillehousing
add saledateconverted date

update NashvilleHousing
set saledateconverted = convert(date, saledate)



--populate Property Address data

select *
from PortfolioProject..NashvilleHousing
--where PropertyAddress is null
order by ParcelID

select a.ParcelID, a.propertyaddress, b.ParcelID, b.PropertyAddress, isnull(a.propertyaddress, b.PropertyAddress)
--when column a is null take it from column b
from PortfolioProject..NashvilleHousing a
join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID   --when have same ParcelID will put the same PropertyAddress
	and a.[UniqueID ] <> b.[UniqueID ]  --uniqueIDs are unique, so need to put them different
where a.PropertyAddress is null

update a
set PropertyAddress = isnull(a.propertyaddress, b.PropertyAddress)
from PortfolioProject..NashvilleHousing a
join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID 
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null



--breaking out Address into individual columns (Address, City, State)

select *
from PortfolioProject..NashvilleHousing
--where PropertyAddress is null
--order by ParcelID

select SUBSTRING(propertyaddress, 1, CHARINDEX(',', PropertyAddress)-1) --minus 1 not have the comma in the output
as Address
, SUBSTRING(propertyaddress, CHARINDEX(',', PropertyAddress)+1, LEN(propertyaddress)) as address
from PortfolioProject..NashvilleHousing

alter table nashvillehousing
add PropertySplitAddress Nvarchar(255)

update NashvilleHousing           --to create a new column
set PropertySplitAddress = SUBSTRING(propertyaddress, 1, CHARINDEX(',', PropertyAddress)-1)

alter table nashvillehousing
add PropertySplitCity Nvarchar(255)

update NashvilleHousing
set PropertySplitCity = SUBSTRING(propertyaddress, CHARINDEX(',', PropertyAddress)+1, LEN(propertyaddress))


select*
from PortfolioProject..NashvilleHousing

--another way for same result

select owneraddress
from PortfolioProject..NashvilleHousing

select
PARSENAME(replace(owneraddress, ',','.'),3) --replace comma with period becase parsename is used to extract specific parts of a string separated by dots
,PARSENAME(replace(owneraddress, ',','.'),2)
,PARSENAME(replace(owneraddress, ',','.'),1)
from PortfolioProject..NashvilleHousing



alter table NashvilleHousing
add OwnerSplitAddress Nvarchar(255)

update nashvillehousing
set OwnerSplitAddress = PARSENAME(replace(owneraddress, ',','.'),3)

alter table nashvillehousing
add OwnerSplitCity Nvarchar(255)

update NashvilleHousing
set OwnerSplitCity = PARSENAME(replace(owneraddress, ',','.'),2)

alter table nashvillehousing
add OwnerSplitState Nvarchar(255)

update NashvilleHousing
set OwnerSplitState = PARSENAME(replace(owneraddress, ',','.'),1)


select*
from PortfolioProject..NashvilleHousing



--change Y and N to Yes and No in "sold as vacant" field

select distinct(SoldAsVacant), count(SoldAsVacant)
from PortfolioProject..NashvilleHousing
group by SoldAsVacant
order by 2


select SoldAsVacant
,case when SoldAsVacant='Y' then 'Yes'
	when SoldAsVacant='N' then 'No'
	else SoldAsVacant
	end
from PortfolioProject..NashvilleHousing

update NashvilleHousing
set SoldAsVacant = case when SoldAsVacant='Y' then 'Yes'
	when SoldAsVacant='N' then 'No'
	else SoldAsVacant
	end



--remove duplicates

with rownumCTE as(
select*,
	row_number() over(
	partition by ParcelID, 
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				order by
					uniqueID
					) row_num
from PortfolioProject..NashvilleHousing
--order by ParcelID
)
delete
from rownumCTE
where row_num>1 --to show only rows that are not the first one in each duplicate group (to be deleted)
--order by PropertyAddress


with rownumCTE as(
select*,
	row_number() over(
	partition by ParcelID, 
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				order by
					uniqueID
					) row_num
from PortfolioProject..NashvilleHousing
--order by ParcelID
)
select*
from rownumCTE
where row_num>1 --to show only rows that are not the first one in each duplicate group (to be deleted)
order by PropertyAddress


select*
from PortfolioProject..NashvilleHousing




--delete unused columns

select*
from PortfolioProject..NashvilleHousing

alter table PortfolioProject..NashvilleHousing
drop column OwnerAddress, TaxDistrict, PropertyAddress

alter table PortfolioProject..NashvilleHousing
drop column SaleDate
