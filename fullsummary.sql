DROP PROCEDURE IF EXISTS `process_xxx`;
CREATE PROCEDURE `process_xxx`(IN companyLocId BIGINT, IN idProgram BIGINT, OUT result VARCHAR(20) )
BEGIN 
   DECLARE totalDataI DECIMAL(18,2)  DEFAULT 0;
	 DECLARE totalDataScanned DECIMAL(18,2)  DEFAULT 0;
	 DECLARE buildPeriod CHAR(20);
	 DECLARE errorsPaid INT DEFAULT 0;
	 DECLARE errorsKul INT DEFAULT 0;
	 DECLARE errorBarcode93 INT DEFAULT 0;
	 DECLARE errorUnPaid INT DEFAULT 0;
	 DECLARE errorPartiallyPaid INT DEFAULT 0;
	 DECLARE errorUnmached INT DEFAULT 0;
	 DECLARE totalErrors DECIMAL(18,2)  DEFAULT 0;
	 DECLARE pErrors DECIMAL(18,2)  DEFAULT 0;
	 DECLARE moveSummariesQTY INT DEFAULT 0;
	 DECLARE muErrors INT DEFAULT 0;
	 DECLARE othersErrors INT DEFAULT 0;
	 DECLARE muTotalErrors INT DEFAULT 0;
	 DECLARE perOther DECIMAL(18,2)  DEFAULT 0;
	 DECLARE per  DECIMAL(18,2)  DEFAULT 0;
	 DECLARE muMailOwnerName VARCHAR(400);
	 DECLARE uErrors DECIMAL(18,8)  DEFAULT 0;
	 DECLARE costToMU DECIMAL(18,2)  DEFAULT 0;
	 
	 SET result ="Incomplete";
	 DELETE FROM IMAPSummary WHERE companyLocId = companyLocId AND idProgram = IdProgram;
	 
	 IF (idProgram <> 2) THEN
	 SET @x = 1;
   WHILE @x <= 2 DO

		 SET buildPeriod = CONCAT(CONVERT(YEAR(SYSDATE()+ INTERVAL -(@x) MONTH),CHAR(4)), LPAD(CONVERT(MONTH(SYSDATE()+ INTERVAL -(@x-1) MONTH ),CHAR(2)),2,'0'), '01'); 
		 SELECT buildPeriod;
		 
		 
	   SET  totalDataI = (SELECT  ct.SeamlessEligible FROM IV_Data.Combined_Totals ct 
		 WHERE  ct.CompanyLocID  = companyLocId AND ct.ErrorInvoicePeriod = buildPeriod LIMIT 1);
		 
		 SET  totalDataScanned = (SELECT  SeamlessScanned  FROM IV_Data.Combined_Totals ct 
		 WHERE  ct.CompanyLocID  = companyLocId AND ct.ErrorInvoicePeriod = buildPeriod LIMIT 1);
		  
		 SET errorsPaid =( SELECT COUNT(1) from IV_Data.Mailed_Undoc_Errors mue
		 WHERE  mue.CompanyLocId = companyLocId AND  mue.ErrorInvoicePeriod = buildPeriod 
		 AND mue.StatementPieceCount >= mue.JobPieceCount);
		 
		 
		 
		 SET errorsKul = (SELECT  COUNT(1) from IV_Data.IV_Documented_KUL mue
		 WHERE  mue.CompanyLocId = companyLocId AND  mue.ErrorInvoicePeriod = buildPeriod);
		 
		 SET errorBarcode93  = (SELECT  COUNT(1) from IV_Data.Redirect_93_Undoc_Errors rue
		 WHERE  rue.CompanyLocId = companyLocId AND  rue.ErrorInvoicePeriod = buildPeriod);
		 
		 SET errorUnPaid  =(SELECT  COUNT(1) from IV_Data.Mailed_Undoc_Errors dmue
		 WHERE  dmue.CompanyLocId = companyLocId AND  dmue.ErrorInvoicePeriod = buildPeriod
		 AND (dmue.StatementPieceCount =0  OR dmue.StatementPieceCount IS NULL));
		 
		 SET errorPartiallyPaid  =(SELECT COUNT(1) from IV_Data.Mailed_Undoc_Errors dmue
		 WHERE  dmue.CompanyLocId = companyLocId AND  dmue.ErrorInvoicePeriod = buildPeriod
		 AND dmue.StatementPieceCount < dmue.JobPieceCount AND dmue.StatementPieceCount>0);
		 
		 SET errorUnmached = (SELECT  COUNT(1) from IV_Data.Unmatched_Undoc_Errors rue
		 WHERE  rue.CompanyLocId = companyLocId AND  rue.ErrorInvoicePeriod = buildPeriod);
		 
		 SET totalErrors  = (SELECT  IFNULL(errorBarcode93,0)  + IFNULL(errorUnmached,0) + IFNULL(errorPartiallyPaid,0) + IFNULL(errorsPaid,0) + IFNULL(errorUnPaid,0));
		 
		 IF (totalDataI >0) THEN
		 SET pErrors=(((IFNULL(errorBarcode93,0)  + IFNULL(errorUnmached,0) + IFNULL(errorPartiallyPaid,0) + IFNULL(errorsPaid,0) + IFNULL(errorUnPaid,0))/totalDataI)*100 );
		 END IF;
		 
		 -- SEAMLESS ACCEPTANCE
		 INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES 
		 (companyLocId, idProgram,22, totalDataI, buildPeriod);
		 
		 INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES 
		 (companyLocId, idProgram,1, totalDataScanned, buildPeriod);
		 
		 INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES 
		 (companyLocId, idProgram,4, errorsPaid, buildPeriod);
		 
		 INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES 
		 (companyLocId, idProgram,5, errorsKul, buildPeriod);
		 
		 INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES 
		 (companyLocId, idProgram, 6, errorBarcode93, buildPeriod);
		 
		 INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES 
		 (companyLocId, idProgram, 7, errorUnPaid, buildPeriod);
		 
     INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES 
		 (companyLocId, idProgram, 8, errorPartiallyPaid, buildPeriod);
		    
	   INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES 
		 (companyLocId, idProgram, 9, errorUnmached, buildPeriod);
		 	
		 INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES 
		 (companyLocId, idProgram, 2, totalErrors, buildPeriod);
		 
		 INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES 
		 (companyLocId, idProgram, 3, pErrors, buildPeriod);
		
		 SET @x = @x +1;
   END WHILE;
	  DROP TABLE IF EXISTS  owners;
		 SET result ="Complete";
		 
	 END IF;
    
		 -- MOVE UPDATE
	 IF (idProgram =2 ) THEN
	 
	 		
	 
	 SET @x = 1;
   WHILE @x <= 2 DO
		 SET buildPeriod = CONCAT(CONVERT(YEAR(SYSDATE()+ INTERVAL -(@x) MONTH),CHAR(4)), LPAD(CONVERT(MONTH(SYSDATE()+ INTERVAL -(@x-1) MONTH ),CHAR(2)),2,'0'), '01'); 
		 
	   SET  totalDataI = (SELECT ct.MoveUpdateEligible FROM IV_Data.Combined_Totals ct  
		 WHERE  ct.CompanyLocID  = companyLocId AND ct.ErrorInvoicePeriod = buildPeriod LIMIT 1);
		 
		 SET moveSummariesQTY = (SELECT COUNT(1) FROM IV_Data.Move_Update_Owner_Summary muo WHERE muo.CompanyLocID = companyLocId  and muo.ErrorInvoicePeriod = buildPeriod);

		 INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES (companyLocId, idProgram,10, totalDataI, buildPeriod);
		 
	   INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES (companyLocId, idProgram,13, moveSummariesQTY, buildPeriod);
			  
			 	DROP TABLE IF EXISTS owners;
				CREATE TEMPORARY TABLE IF NOT EXISTS owners
				(id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY
				, CompanyLocID BIGINT
				, MailOwnerCRID varchar(20)
				, MU_ErrorCount int
				, MailerOwnerName varchar(100)
				, buildPeriodTemp varchar(20));
				INSERT INTO owners (CompanyLocID,MailOwnerCRID,MU_ErrorCount,MailerOwnerName,buildPeriodTemp ) 
				SELECT ma.CompanyLocID,ma.MailOwnerCrid, ma.MU_ErrorCount,ma.MailOwnerName
				,buildPeriod
				FROM IV_Data.Move_Update_Owner_Summary ma WHERE
				ma.CompanyLocID = companyLocId AND	ma.ErrorInvoicePeriod = buildPeriod ORDER BY MU_ErrorCount DESC;
				
				SET @qtyMU = (SELECT COUNT(1) FROM owners);
				SET @j = 1;
				WHILE @j <= 5 DO
					 IF (@qtyMU > @j) THEN
					  SET muErrors = muErrors + (SELECT MU_ErrorCount FROM owners WHERE id = @j);
					 END IF;
					SET @j = @j +1;
				END WHILE;
			
				if (@qtymu >5) then
					set @k = 6;
							while @k <= @qtymu do
							if (@qtymu >= @k) then
								set otherserrors = otherserrors + (select mu_errorcount from owners where id = @k);
								select otherserrors, @k;
							end if;
							set @k = @k +1;
						end while;
				end if;
				
	
				SET muTotalErrors = muErrors +othersErrors;
				IF (muTotalErrors =0) THEN
						INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES (companyLocId, idProgram,20, 0, buildPeriod);
						INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES (companyLocId, idProgram,11, 0, buildPeriod);
						INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES (companyLocId, idProgram,12, 0, buildPeriod);
						INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES (companyLocId, idProgram,14, 0, buildPeriod);
						
						INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES (companyLocId, idProgram,15, 0, buildPeriod);
						INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES (companyLocId, idProgram,16, 0, buildPeriod);
						INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES (companyLocId, idProgram,17, 0, buildPeriod);
						INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES (companyLocId, idProgram,18, 0, buildPeriod);
						INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES (companyLocId, idProgram,19, 0, buildPeriod);

						
				ELSE
					SET perOther = 100 * (othersErrors / muTotalErrors);
					INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period,SummaryValuePer) VALUES (companyLocId, idProgram,20, othersErrors, buildPeriod, perOther);
					SET @p = 1;
							WHILE @p <= 5 DO
							SET @pos = 14 + @p;
							IF (@qtyMU > @p) THEN
							  SET @errorOnwer = (SELECT MU_ErrorCount FROM owners WHERE id = @p);
								SET per = 100 * (@errorOnwer / muTotalErrors);
								SET muMailOwnerName = (SELECT muMailOwnerName FROM owners WHERE id = @p);
								INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period,SummaryValuePer, SummaryOwner) 
								VALUES (companyLocId, idProgram,@pos,@errorOnwer, buildPeriod, per, muMailOwnerName);
							ELSE
								INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period,SummaryValuePer, SummaryOwner) VALUES (companyLocId, idProgram,@pos, 0, buildPeriod,0,'');
							END IF;
							SET @p = @p +1;
						END WHILE;
					  
						INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES (companyLocId, idProgram,11, muTotalErrors, buildPeriod);
					  
						
						IF(totalDataI >0) THEN
						 SET uErrors = (muTotalErrors / totalDataI)*100;
						END IF; 
					
						INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES (companyLocId, idProgram,12, uErrors, buildPeriod);
						
						IF (uErrors > 0.50) THEN
						   SET costToMU =(((uErrors - 0.5) / uErrors) * 0.08 * muTotalErrors);
						END IF;
						INSERT INTO IMAPSummary (PwCompanyLocId, IdProgram, IdCategory, SummaryValue, Period) VALUES (companyLocId, idProgram,14, costToMU, buildPeriod);
						
						
				END IF;
			
			  
				DELETE FROM owners;
		
	   
		 SET @x = @x +1;
   END WHILE;
	 	 SET result ="Complete";
	 END IF;
	 
	 
	END
