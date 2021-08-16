conn apps/&1
alter table swgcnv.SWGCNV_TYPE add approval_flag varchar2(1) default 'N';
--
update  swgcnv_type
set approval_flag = 'Y'
where system_code != 'WTRFLX2';
--
commit;
--
exit;
