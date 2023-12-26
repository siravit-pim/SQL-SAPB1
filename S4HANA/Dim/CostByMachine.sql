WITH incremental AS (
	WITH Summarize AS (
		WITH COSSS AS (
			SELECT 'Other' as "Type", 0 AS Amount, COSS.OBJNR,
				SUBSTRING(COSS.OBJNR,3,12) AS ProductionOrder,
				COSS.KSTAR AS CostElement,
				SKAT.TXT20 AS CostElementName,		
				CASE WHEN COSS.USPOB <> '' THEN SUBSTRING(COSS.USPOB,7,10) ELSE '' END AS CostCenter,
				IFNULL(CSKT.KTEXT,'') AS CostCenterName,
				COSS.GJAHR AS FiscalYear,
				COSS.MEINH AS Meas,
				AFPO.MATNR AS Material,
				MAKT.MAKTX AS MaterialDesc,
				MKAL.TEXT1 AS ProductionVersionText,
				AFPO.DWERK AS Plant,
				CASE WHEN AFKO.ATRKZ = 'Z' THEN 'Yes' ELSE '' END AS CombineOrder,
				CASE WHEN AFKO.ATRKZ = 'U' THEN 'Yes' ELSE '' END AS OriginalOrder,
				T003P.TXT AS OrderType,
				IFNULL(CRHD1.ARBPL || ',' || CRHD2.ARBPL,CRHD1.ARBPL) AS Machine,
				AFPO.AUFNR, AFPO.MATNR, AFPO.DWERK, 999 UMREN, 999 UMREZ, AFKO.ATRKZ, BEKNZ, COSS.KSTAR
			FROM SAPHANADB.COSS COSS
			INNER JOIN SAPHANADB.SKAT SKAT ON COSS.KSTAR = SKAT.SAKNR AND SKAT.MANDT = '900' AND SKAT.SPRAS = 'E'		
			INNER JOIN SAPHANADB.AFPO AFPO ON SUBSTRING(COSS.OBJNR,3,12) = AFPO.AUFNR AND AFPO.MANDT = '900'	
			LEFT  JOIN SAPHANADB.MAKT MAKT ON AFPO.MATNR = MAKT.MATNR AND MAKT.MANDT = '900' AND MAKT.SPRAS = 'E'		
			INNER JOIN SAPHANADB.MKAL MKAL ON  AFPO.MATNR = MKAL.MATNR AND AFPO.DWERK = MKAL.WERKS  AND AFPO.VERID = MKAL.VERID AND MKAL.MANDT = '900'	
			INNER JOIN SAPHANADB.AFKO AFKO ON AFPO.AUFNR = AFKO.AUFNR AND AFKO.MANDT = '900'
			INNER JOIN (
        				SELECT  AFVC.AUFPL,MIN(AFVC.ARBID) AS ARBID,MAX(CASE WHEN AFVC.VORNR = '0010' THEN AFVC.ARBID ELSE '' END) AS ARBID_1,MAX(CASE WHEN AFVC.VORNR = '0020' THEN AFVC.ARBID ELSE '' END) AS ARBID_2
        				FROM SAPHANADB.AFVC AFVC
        				WHERE AFVC.MANDT = '900' 
        				GROUP BY AFVC.AUFPL
        			) AFVC_1 ON AFKO.AUFPL = AFVC_1.AUFPL
			LEFT JOIN SAPHANADB.CRHD CRHD1 ON AFVC_1.ARBID_1 = CRHD1.OBJID AND CRHD1.MANDT = '900'
			LEFT JOIN SAPHANADB.CRHD CRHD2 ON AFVC_1.ARBID_2 = CRHD2.OBJID AND CRHD2.MANDT = '900'
			INNER JOIN SAPHANADB.AUFK AUFK ON AFPO.AUFNR = AUFK.AUFNR AND AUFK.MANDT = '900'
			INNER JOIN SAPHANADB.T003P ON AUFK.AUART = T003P.AUART AND T003P.CLIENT = '900' AND T003P.SPRAS = 'E'
			------------------------------
			LEFT JOIN SAPHANADB.CSKT ON SUBSTRING(COSS.USPOB,7,10) = CSKT.KOSTL AND CSKT.MANDT = '900' AND CSKT.SPRAS = 'E'
			WHERE COSS.MANDT = '900' AND COSS.WRTTP = '04' AND COSS.VERSN = '000' AND LEDNR = '00'
		),
		COSPP2 as (
			WITH COSPP as (
				SELECT COSS.OBJNR,
					SUBSTRING(COSS.OBJNR,3,12) AS ProductionOrder,
					COSS.KSTAR AS CostElement,
					SKAT.TXT20 AS CostElementName,		
					(SELECT MAX(SUBSTRING(A.USPOB,7,10)) FROM SAPHANADB.COSS A WHERE A.OBJNR = COSS.OBJNR AND A.GJAHR = COSS.GJAHR ) AS "CostCenter",
					'' AS CostCenterName,
					COSS.GJAHR AS FiscalYear,	
					COSS.MEINH AS Meas,
					AFPO.MATNR AS Material,
					MAKT.MAKTX AS MaterialDesc,
					MKAL.TEXT1 AS ProductionVersionText,
					AFPO.DWERK AS Plant,
					CASE WHEN AFKO.ATRKZ = 'Z' THEN 'Yes' ELSE '' END AS CombineOrder,
					CASE WHEN AFKO.ATRKZ = 'U' THEN 'Yes' ELSE '' END AS OriginalOrder,
					T003P.TXT AS OrderType,
					IFNULL(CRHD1.ARBPL || ',' || CRHD2.ARBPL, CRHD1.ARBPL) AS Machine,
					AFPO.AUFNR, AFPO.MATNR, AFPO.DWERK, MARM.UMREN, MARM.UMREZ, AFKO.ATRKZ, BEKNZ, COSS.KSTAR
				FROM SAPHANADB.COSP COSS
				INNER JOIN SAPHANADB.SKAT ON COSS.KSTAR = SKAT.SAKNR AND SKAT.MANDT = '900' AND SKAT.SPRAS = 'E' --CostElementName		
				INNER JOIN SAPHANADB.AFPO ON SUBSTRING(COSS.OBJNR,3,12) = AFPO.AUFNR AND AFPO.MANDT = '900'	--Material, plant / important for many join
				LEFT  JOIN SAPHANADB.MAKT ON AFPO.MATNR = MAKT.MATNR AND MAKT.MANDT = '900' AND MAKT.SPRAS = 'E' --MaterialDesc	 	
				INNER JOIN SAPHANADB.MKAL ON AFPO.MATNR = MKAL.MATNR AND AFPO.DWERK = MKAL.WERKS  AND AFPO.VERID = MKAL.VERID AND MKAL.MANDT = '900' --ProductionText	
				INNER JOIN SAPHANADB.AFKO ON AFPO.AUFNR = AFKO.AUFNR AND AFKO.MANDT = '900' --Check Combine/OriOrder and Key for `AFVC`
				INNER JOIN ( -- about machine 1,2
							SELECT  AFVC.AUFPL,
								MIN(AFVC.ARBID) AS ARBID,
								MAX(CASE WHEN AFVC.VORNR = '0010' THEN AFVC.ARBID ELSE '' END) AS ARBID_1,
								MAX(CASE WHEN AFVC.VORNR = '0020' THEN AFVC.ARBID ELSE '' END) AS ARBID_2
							FROM SAPHANADB.AFVC
							WHERE AFVC.MANDT = '900' 
							GROUP BY AFVC.AUFPL
						) AFVC_1 ON AFKO.AUFPL = AFVC_1.AUFPL
				LEFT JOIN SAPHANADB.CRHD CRHD1 ON AFVC_1.ARBID_1 = CRHD1.OBJID AND CRHD1.MANDT = '900' -- about machine (1)
				LEFT JOIN SAPHANADB.CRHD CRHD2 ON AFVC_1.ARBID_2 = CRHD2.OBJID AND CRHD2.MANDT = '900' -- about machine (2)
				INNER JOIN SAPHANADB.AUFK ON AFPO.AUFNR = AUFK.AUFNR AND AUFK.MANDT = '900' --key for `T003P`
				INNER JOIN SAPHANADB.T003P ON AUFK.AUART = T003P.AUART AND T003P.CLIENT = '900' AND T003P.SPRAS = 'E' --Order TYPE
				INNER JOIN SAPHANADB.MARM ON AFPO.MATNR = MARM.MATNR AND MARM.MANDT = '900' AND MARM.MEINH = 'KG'
				WHERE COSS.MANDT = '900' AND COSS.WRTTP = '04' AND COSS.VERSN = '000'
			)
			-- REJECT
			SELECT 'Reject' as "Type", *
			FROM COSPP 
			WHERE ATRKZ <> 'U' AND KSTAR IN('0084330012', '0052110400')
			-- COIL
				UNION ALL 
			SELECT 'Coil' AS "Type", *
			FROM COSPP
			WHERE ATRKZ = 'Z' AND KSTAR BETWEEN '0054110100' AND '0054110400'
			-- PRODUCTION
		    	UNION ALL 
			SELECT 'Production' as "Type", COSPP.*
			FROM COSPP
			INNER JOIN (
					SELECT MATDOC.AUFNR,MATDOC.WERKS,MATDOC.MATNR, MATDOC.BLDAT,
						SUM(CASE WHEN MATDOC.SHKZG = 'S' THEN  MATDOC.MENGE * 1  WHEN MATDOC.SHKZG = 'H'	THEN  MATDOC.MENGE * -1  END) AS MENGE_SUM 
					FROM SAPHANADB.MATDOC
					WHERE MATDOC.BWART IN('101','102') AND MATDOC.MANDT = '900'
					GROUP BY MATDOC.AUFNR,MATDOC.WERKS,MATDOC.MATNR, MATDOC.BLDAT
				) AS MATDOCS ON COSPP.AUFNR = MATDOCS.AUFNR AND COSPP.MATNR = MATDOCS.MATNR AND COSPP.DWERK = MATDOCS.WERKS AND YEAR(MATDOCS.BLDAT) = COSPP.FiscalYear
			WHERE COSPP.ATRKZ <> 'Z' AND COSPP.BEKNZ = 'L'
		    
		) 
		SELECT 
			"Type",
			Plant AS "Plant",
			CostCenter AS "CostCenter",
			Machine AS "Machine" ,
			CostElement AS "CostElement", CostElementName AS "CostElementName",
			ProductionOrder AS "ProductionOrder", ProductionVersionText AS "ProductionVersionText",
			Material,MaterialDesc,OrderType
		FROM COSSS
		    
			UNION ALL -- Merge COSS/COSP
		SELECT 
			"Type",
			Plant AS "Plant",
			"CostCenter",
			Machine AS "Machine",
			CostElement AS "CostElement",CostElementName AS "CostElementName",
			ProductionOrder AS "ProductionOrder",ProductionVersionText AS "ProductionVersionText",
			Material,MaterialDesc,OrderType
		FROM COSPP2
	)
	SELECT DISTINCT
		CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM 
			IFNULL(A."Type",'')||IFNULL(A."Plant",'')||IFNULL(A."Machine",'')||IFNULL(A."CostCenter",'')||IFNULL(A."CostElement",'')||IFNULL(A."ProductionOrder",'')||IFNULL(A.Material,'')
		)))) as NVARCHAR(32)) as "CostByMachine_Key",
		A."Type",
		A."Plant",
		A."Machine",
		A."CostCenter",
		LTRIM(A."CostElement",'0') AS "CostElement", A."CostElementName",
		A."ProductionOrder",A."ProductionVersionText",
		LTRIM(A.Material,0) AS Material ,
		A.MaterialDesc,
		A.OrderType,
		prd."ProductTypeDesc" as "MaterialType",
		prd."ProductGroup_PD" as "MaterialGroup",
		prd."Brand",
		prd."Standard",
		prd."ProductPurpose",
		prd."ProductSize" as "SizePM",
		MapGroup."GroupIndex",
		MapGroup."GroupLevel1",
		MapGroup."GroupReport",
		MapGroup."GroupConversion",
		MapGroup."Unit"
	FROM Summarize A
	LEFT JOIN "XXXXX"."DimMapGroupCost" MapGroup ON  MapGroup."CostElement" = A."CostElement" OR
		( SUBSTRING_REGEXPR('[^_]+' IN MapGroup."CostElement" OCCURRENCE 1) = A."CostElement" )
	LEFT JOIN "XXXXX"."DimProductMaster" prd ON prd."ProductCode" = LTRIM(A.Material,0)
)
SELECT 	*,
    TO_DATE(CURRENT_TIMESTAMP) AS START_DATE,
	TO_DATE('9999-12-31') AS END_DATE,
	1 AS ACTIVE,
	CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM
		IFNULL("CostByMachine_Key",'') 
	)))) as NVARCHAR(32)) AS HASH_KEY,
	CAST(HASH_MD5(TO_BINARY(UPPER(TRIM(' ' FROM
		IFNULL("CostByMachine_Key",'') ||
		IFNULL("CostElementName",'') ||
		IFNULL("ProductionVersionText",'') ||
		IFNULL(MaterialDesc,'') ||
		IFNULL("MaterialType",'') ||
		IFNULL("MaterialGroup",'') ||
		IFNULL(OrderType,'') ||
		IFNULL("Brand",'') ||
		IFNULL("Standard",'') ||
		IFNULL("ProductPurpose",'') ||
		IFNULL("SizePM",'') ||
		IFNULL("GroupIndex",0) ||
		IFNULL("GroupLevel1",'') ||
		IFNULL("GroupReport",'') ||
		IFNULL("GroupConversion",'') ||
		IFNULL("Unit",'') 
	)))) as NVARCHAR(32)) AS HASH_DIFF
FROM incremental
