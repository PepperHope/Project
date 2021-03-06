CREATE OR REPLACE PROCEDURE p_discard(ip_product IN T_PRODUCT) IS
	v_product					 T_PRODUCT;
	v_state   					 T_STATE;
	RETURN_TO_THE_LAST_PUBLISHED BOOLEAN DEFAULT FALSE;
	v_id_of_last_published       NUMBER;
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
	
	IF    v_product.status_id = /* PENDING_APPROVAL_ID */ AND v_product.was_published = 0 THEN
		v_state = T_STATE(0,1,0,/* DISCARDED_ID */,/* DISCARD */);
	ELSIF v_product.status_id = /* PENDING_APPROVAL_ID */ AND v_product.was_published = 1 THEN
		v_state = T_STATE(1,1,1,/* APPROVED_ID */,/* DISCARD */);
		RETURN_TO_THE_LAST_PUBLISHED := TRUE;
	ELSIF v_product.status_id = /* PENDING_APPROVAL_ID */ AND v_product.was_published = 1 THEN
		v_state = T_STATE(1,1,1,/* DEACTIVATED_ID */,/* DISCARD */);
		RETURN_TO_THE_LAST_PUBLISHED := TRUE;
	ELSIF v_product.status_id = /* APPROVED_ID */ THEN
		v_state = T_STATE(0,1,1,/* PENDING_APPROVAL_ID */,/* DISCARD */);
	END IF;
	
	IF RETURN_TO_THE_LAST_PUBLISHED THEN
		SELECT PRODUCT.product_id INTO v_id_of_last_published
		  FROM PRODUCT
		 WHERE PRODUCT.group_id  = ip_product.group_id
		   AND PRODUCT.publish = 1
		   AND PRODUCT.status_id = v_state.status_id;
		
		UPDATE PRODUCT
		   SET PRODUCT.last_record = v_state.last_record
		       PRODUCT.last_action_id = v_state.last_action_id
		 WHERE PRODUCT.product_id = v_id_of_last_published;
	ELSE
		INSERT INTO PRODUCT
		VALUES(seq_prod_product_id.NEXTVAL,
			   PRODUCT.group_id,
			   PRODUCT.product_uid, 
			   PRODUCT.product_name, 
			   PRODUCT.product_long_name
			   PRODUCT.description, 
			   PRODUCT.valid_start_date,
			   v_state.status_id,
			   v_state.last_action_id,
			   v_state.publish,
			   v_state.last_record,
			   PRODUCT.linked,
			   v_state.was_published,
			   PRODUCT.comments,
			   PRODUCT.active_flag,
			   USER,
			   CURRENT_DATE,
			   PRODUCT.created_by,
			   PRODUCT.created_date);
	END IF;
	
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
END p_discard;