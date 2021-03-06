CREATE OR REPLACE PROCEDURE p_amend(ip_product IN T_PRODUCT, ip_lnk_feature IN T_LNK_FEATURE) IS
	v_product T_PRODUCT;
	v_state   T_STATE;
BEGIN
	SELECT * INTO v_product
	  FROM PRODUCT
	 WHERE PRODUCT.product_id = ip_product.product_id;
	 
	/* **********************************************
	 THE PLACE FOR CHECKS WHICH THROW EXCEPTIONS
	 ********************************************** */
	CASE
		WHEN SQL%NOTFOUND THEN RAISE NO_DATA_FOUND
	END;
	/* **********************************************
	 ////////////////////////////////////////////////
	 ********************************************** */
	
	IF    v_product.status_id = /* APPROVED_ID */ THEN
		v_state = T_STATE(0,1,1,/* PENDING_APPROVAL_ID */,/* AMEND */);
	ELSIF v_product.status_id = /* PENDING_APPROVAL_ID */ THEN
		v_state = T_STATE(0,1,0,/* PENDING_APPROVAL_ID */,/* AMEND */);
	ELSIF v_product.status_id = /* REJECTED_ID */ THEN
		v_state = T_STATE(0,1,0,/* PENDING_APPROVAL_ID */,/* AMEND */);
	ELSIF v_product.status_id = /* DISCARDED_ID */ THEN
		v_state = T_STATE(0,1,0,/* PENDING_APPROVAL_ID */,/* AMEND */);
	END IF;
	
	INSERT INTO PRODUCT
	VALUES(seq_prod_product_id.NEXTVAL,
		   PRODUCT.group_id,
		   PRODUCT.product_uid, 
		   COALESCE(ip_product.product_name,		PRODUCT.product_name), 
		   COALESCE(ip_product.product_long_name,	PRODUCT.product_long_name), 
		   COALESCE(ip_product.description,			PRODUCT.description), 
		   COALESCE(ip_product.valid_start_date,	PRODUCT.valid_start_date),
		   v_state.status_id,
		   v_state.last_action_id,
		   v_state.publish,
		   v_state.last_record,
		   PRODUCT.linked,
		   v_state.was_published,
		   COALESCE(ip_product.comments,        	PRODUCT.comments),
		   PRODUCT.active_flag,
		   USER,
		   CURRENT_DATE,
		   PRODUCT.created_by,
		   PRODUCT.created_date);
	
	UPDATE PRODUCT
	   SET PRODUCT.last_record = 0
	 WHERE PRODUCT.product_id = ip_product.product_id;
	 
EXCEPTION
	/* **********************************************
	 THE PLACE FOR EXCEPTIONS
	 ********************************************** */
	WHEN NO_DATA_FOUND THEN
		RAISE_APPLICATION_ERROR(/* ERROR CODE */,/* ERROR TEXT */);
	/* **********************************************
	 ////////////////////////////////////////////////
	 ********************************************** */
END p_amend;