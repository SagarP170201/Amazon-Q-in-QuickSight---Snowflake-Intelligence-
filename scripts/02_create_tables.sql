-- XpressBees Profitability AI Agent - Table Creation DDL
-- Run after 01_setup_database.sql

USE DATABASE XPRESSBEES_PROFITABILITY;
USE SCHEMA RAW;
USE WAREHOUSE SNOW_INTELLIGENCE_DEMO_WH;

CREATE TABLE IF NOT EXISTS B2B_REVENUE (
    "AWB No" VARCHAR, "Revenue Type" VARCHAR, "Origin HubName" VARCHAR,
    "Destination HubName" VARCHAR, "MPS Count" NUMBER(10,0),
    "Physical Weight" NUMBER(18,4), "Volumetric Weight" NUMBER(18,4),
    "Bill Weight" NUMBER(18,4), "Freight" NUMBER(18,2),
    "Fuel Surcharge" NUMBER(18,2), FOV NUMBER(18,2),
    "AWB Charges" NUMBER(18,2), "Green Tax" NUMBER(18,2),
    "Appointment Charges" NUMBER(18,2), "ODA PickUp Charges" NUMBER(18,2),
    "ODA Delivery Charges" NUMBER(18,2), "Mathadi Charges" NUMBER(18,2),
    "Floor Delivery Charges" NUMBER(18,2), "Open PickUp Charges" NUMBER(18,2),
    "Loading/ Unloading/ Other Charges" NUMBER(18,2),
    "Handling Charges" NUMBER(18,2), "Net Charges" NUMBER(18,2),
    "InScan Date" VARCHAR, "Client ID" VARCHAR, "Client Name" VARCHAR,
    "Route" VARCHAR, "Destn Hub Type" VARCHAR,
    "BA pickup - BA pickup Cost" NUMBER(18,2),
    "Other pickups - Vehicle Cost" NUMBER(18,2),
    "Fix Cost Pick-up" NUMBER(18,2), "Pickup Cost" NUMBER(18,2),
    "BA delivery - BA delivery Cost" NUMBER(18,2),
    "Other delivery - Vehicle Cost" NUMBER(18,2),
    "Fix Cost Delivery" NUMBER(18,2), "Manpower Cost at SVC" NUMBER(18,2),
    "Delivery Cost" NUMBER(18,2), "Manpower Cost for LM delivery" NUMBER(18,2),
    "Milkrun Cost" NUMBER(18,2),
    "Feeder Cost - From Pickup branch / Hub till LH Hub" NUMBER(18,2),
    "Linehaul Cost" NUMBER(18,2), "Midmile Cost" NUMBER(18,2),
    "FM handling" NUMBER(18,2), "LM Handling" NUMBER(18,2),
    "MM Handling" NUMBER(18,2), "Handling Cost" NUMBER(18,2),
    "Common Costs" NUMBER(18,2), "Demurrage Charges" NUMBER(18,2),
    "Delivery reattempt Charges" NUMBER(18,2), "CN%" NUMBER(18,4),
    "Credit Notes" NUMBER(18,2), "Other Costs" NUMBER(18,2),
    "Total Cost" NUMBER(18,2), "Margin" NUMBER(18,2),
    "MM Cost%" NUMBER(18,4), "Del Date" VARCHAR, "Del Date2" VARCHAR,
    "Flag" VARCHAR, "Vol FT3" NUMBER(18,4), "merge1" VARCHAR,
    TOT_PHYWT NUMBER(18,4), TOT_VOLWT NUMBER(18,4),
    MPS_COUNT NUMBER(10,0), "clientid" VARCHAR, "status" VARCHAR,
    "phyweight" NUMBER(18,4), "volweight" NUMBER(18,4),
    TOT_CHRGWT NUMBER(18,4), "Billable_CFT" NUMBER(18,4),
    "Density" NUMBER(18,4), MEDIAN_DENSITY NUMBER(18,4),
    "Calculated_CFT" NUMBER(18,4), "Calculated_CFT_CAPPED" NUMBER(18,4),
    "CFT_Hybrid" NUMBER(18,4), "Origin_City" VARCHAR,
    "Origin_Terr" VARCHAR, "Dest_City" VARCHAR, "Dest_Terr" VARCHAR,
    PICKUPDATE VARCHAR, "Density Bucket" VARCHAR, "Client Group" VARCHAR,
    "Territory" VARCHAR, "TSM.Name" VARCHAR, "Zone" VARCHAR,
    "ZSM.Name" VARCHAR
);

CREATE TABLE IF NOT EXISTS AWB_FILE (
    "parentawbno" VARCHAR, "pdd" VARCHAR
);

CREATE TABLE IF NOT EXISTS FM_JOURNEY (
    AWB VARCHAR, PICKUPDATE VARCHAR, FM_TRIPID VARCHAR,
    ORIGINHUB VARCHAR, PICKUPPINCODE VARCHAR, "ODA/NORMAL" VARCHAR
);

CREATE TABLE IF NOT EXISTS LM_JOURNEY (
    AWB VARCHAR, RADDATE VARCHAR, LM_TRIPID VARCHAR,
    DESTHUB VARCHAR, ISMALLDELIVERY VARCHAR,
    TOTALATTEMPTCOUNT VARCHAR, DELIVERYDATETIME VARCHAR,
    DELIVERYPINCODE VARCHAR, "ODA/NORMAL" VARCHAR, "APPT/NORMAL" VARCHAR
);

CREATE TABLE IF NOT EXISTS MM_JOURNEY (
    "TRIP ORDER" NUMBER(10,0), AWB VARCHAR, CONNECTIONTYPE VARCHAR,
    MM_TRIPID VARCHAR, CONNECTIONID VARCHAR,
    CONNECTIONSCHEDULEMASTERID VARCHAR,
    "DEPART_LOCATION (Loading)" VARCHAR,
    "ARRIVAL_LOCATION (UnLoading)" VARCHAR
);

CREATE TABLE IF NOT EXISTS DAILY_LOAD (
    "row_num" VARCHAR, "stoppointorder" NUMBER(10,0),
    "connectionid" VARCHAR, AWB VARCHAR, "TRIP ORDER" NUMBER(10,0),
    MM_TRIPID VARCHAR, CLIENTID VARCHAR, CLIENTNAME VARCHAR,
    MPS_COUNT NUMBER(10,0), TOT_PHYWT NUMBER(18,4),
    TOT_VOLWT NUMBER(18,4), TOT_CHRGWT NUMBER(18,4),
    STOPPOINTHUBNAME VARCHAR, "Departure_time_stoppointhub" VARCHAR,
    "final_connection_name" VARCHAR, "Loading_city" VARCHAR,
    "Unloading_city" VARCHAR, "DEPART_LOCATION (Loading)" VARCHAR,
    "ARRIVAL_LOCATION (UnLoading)" VARCHAR, "Trip_start_date" VARCHAR,
    "Trip_close_date" VARCHAR, "LH Cost" NUMBER(18,4),
    PICKUPDATE VARCHAR, ORIGINHUB VARCHAR,
    DELIVERYDATETIME VARCHAR, DESTHUB VARCHAR,
    FULLCONNECTIONNAME VARCHAR, CONNECTIONENDHUB VARCHAR,
    CONNECTIONSTARTHUB VARCHAR
);

CREATE TABLE IF NOT EXISTS WEIGHTED_UTILIZATION (
    "Start Date Day" VARCHAR,
    "Start Date" VARCHAR,
    "Close Date" VARCHAR,
    "connectionid" VARCHAR,
    "TripSheetNo" VARCHAR,
    "stoppointorder" VARCHAR,
    "Final connection name" VARCHAR,
    "Lane" VARCHAR,
    "Route type" VARCHAR,
    "load_unloadcity" VARCHAR,
    "vehiclename" VARCHAR,
    "Phy Wt" VARCHAR,
    "Phy wt Ecomm" VARCHAR,
    "Phy wt Cargo" VARCHAR,
    "Vol Wt" VARCHAR,
    "Vol wt Ecomm" VARCHAR,
    "Vol wt Cargo" VARCHAR,
    "Chg Wt" VARCHAR,
    "Chg wt Ecomm" VARCHAR,
    "Chg wt Cargo" VARCHAR,
    "Phy Cap" VARCHAR,
    "Vol Cap" VARCHAR,
    "Chg Cap" VARCHAR,
    "Dist." VARCHAR,
    "LU_Phy" VARCHAR,
    "LU_Vol" VARCHAR,
    "LU_Chg" VARCHAR,
    "WC_Phy" VARCHAR,
    "WC_Vol" VARCHAR,
    "WC_Chg" VARCHAR,
    "WA_Phy" VARCHAR,
    "WA_Vol" VARCHAR,
    "WA_Chg" VARCHAR,
    "WU_Phy" VARCHAR,
    "WU_Vol" VARCHAR,
    "WU_Chg" VARCHAR,
    "Cost Leg wise" VARCHAR,
    "LPK_Phy" VARCHAR,
    "LPK_Vol" VARCHAR,
    "LPK_Chg" VARCHAR,
    "TC_Phy" VARCHAR,
    "TC_Vol" VARCHAR,
    "TC_Chg" VARCHAR,
    "CD_Phy" VARCHAR,
    "CD_Vol" VARCHAR,
    "CD_Chg" VARCHAR,
    "Trip Cost" VARCHAR,
    "Dist Sum" VARCHAR,
    "IGN_Phy_wt_Ecomm" VARCHAR,
    "IGN_Phy_wt_Cargo" VARCHAR,
    "IGN_Vol_wt_Ecomm" VARCHAR,
    "IGN_Vol_wt_Cargo" VARCHAR,
    "IGN_Phy_Cap" VARCHAR,
    "IGN_Vol_Cap" VARCHAR,
    "IGN_Chg_Cap" VARCHAR,
    "IGN_Phy_Wt" VARCHAR,
    "IGN_Vol_Wt" VARCHAR,
    "IGN_Chg_Wt" VARCHAR,
    "Vendor_Name" VARCHAR,
    "Start" VARCHAR,
    "Close" VARCHAR,
    "Dedicated Route as per Mapping" VARCHAR,
    "Cost_sharing" VARCHAR,
    "New_trip_cost" VARCHAR,
    "Vehicle_Volume" VARCHAR,
    "Vehicle hired type" VARCHAR,
    "Cargo Cost" VARCHAR,
    "Ecom Cost" VARCHAR,
    "PK_at_90%" VARCHAR,
    "Cargo Cost on billed weight" VARCHAR,
    "Start date Month" VARCHAR,
    "Start date Year" VARCHAR,
    "Ecom ComP" VARCHAR,
    "Cargo comp" VARCHAR,
    "Ecom_vol_Cap" VARCHAR,
    "Cargo_Vol_Cap" VARCHAR,
    "TTL_Vol_Cap" VARCHAR,
    "Min_Vol_Cap" VARCHAR,
    "Max_Vol_Cap" VARCHAR,
    "Date" VARCHAR,
    "Ecomm Comp Volm" VARCHAR,
    "Cargo Comp Volm" VARCHAR
);

CREATE TABLE IF NOT EXISTS DIM_HUB_CITY (
    "HubName" VARCHAR, "HubState" VARCHAR,
    "HubCity" VARCHAR, "Territory" VARCHAR
);

CREATE TABLE IF NOT EXISTS DIM_HUB_TO_ZONE (
    "hubid" VARCHAR, "hubname" VARCHAR, "hubzoneid" VARCHAR,
    "hubzonename" VARCHAR, "centertype" VARCHAR, "isactive" VARCHAR
);

CREATE TABLE IF NOT EXISTS DOC_CHUNKS (
    DOC_NAME VARCHAR, CHUNK_ID NUMBER(38,0), CHUNK_TEXT VARCHAR
);
