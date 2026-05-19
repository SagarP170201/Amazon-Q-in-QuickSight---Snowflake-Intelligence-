-- XpressBees Profitability AI Agent - Table Creation DDL
-- Run after 01_setup_database.sql
-- Tables use proper data types matching parquet source files

USE DATABASE XPRESSBEES_PROFITABILITY;
USE SCHEMA RAW;
USE WAREHOUSE SNOW_INTELLIGENCE_DEMO_WH;

-- Drop existing tables (if rebuilding from parquet)
DROP TABLE IF EXISTS B2B_REVENUE;
DROP TABLE IF EXISTS AWB_FILE;
DROP TABLE IF EXISTS FM_JOURNEY;
DROP TABLE IF EXISTS LM_JOURNEY;
DROP TABLE IF EXISTS MM_JOURNEY;
DROP TABLE IF EXISTS DAILY_LOAD;
DROP TABLE IF EXISTS WEIGHTED_UTILIZATION;

CREATE TABLE B2B_REVENUE (
    "AWB No" VARCHAR,
    "Revenue Type" VARCHAR,
    "Origin HubName" VARCHAR,
    "Destination HubName" VARCHAR,
    "MPS Count" FLOAT,
    "Physical Weight" FLOAT,
    "Volumetric Weight" FLOAT,
    "Bill Weight" FLOAT,
    "Freight" VARCHAR,
    "Fuel Surcharge" VARCHAR,
    "FOV" VARCHAR,
    "AWB Charges" VARCHAR,
    "Green Tax" VARCHAR,
    "Appointment Charges" VARCHAR,
    "ODA PickUp Charges" VARCHAR,
    "ODA Delivery Charges" VARCHAR,
    "Mathadi Charges" VARCHAR,
    "Floor Delivery Charges" VARCHAR,
    "Open PickUp Charges" VARCHAR,
    "Loading/ Unloading/ Other Charges" VARCHAR,
    "Handling Charges" VARCHAR,
    "Net Charges" FLOAT,
    "InScan Date" TIMESTAMP_TZ,
    "Client ID" FLOAT,
    "Client Name" VARCHAR,
    "Route" VARCHAR,
    "Destn Hub Type" VARCHAR,
    "BA pickup - BA pickup Cost" FLOAT,
    "Other pickups - Vehicle Cost" FLOAT,
    "Fix Cost Pick-up" FLOAT,
    "Pickup Cost" FLOAT,
    "BA delivery - BA delivery Cost" FLOAT,
    "Other delivery - Vehicle Cost" FLOAT,
    "Fix Cost Delivery" FLOAT,
    "Manpower Cost at SVC" FLOAT,
    "Delivery Cost" FLOAT,
    "Manpower Cost for LM delivery" VARCHAR,
    "Milkrun Cost" FLOAT,
    "Feeder Cost - From Pickup branch / Hub till LH Hub" FLOAT,
    "Linehaul Cost" FLOAT,
    "Midmile Cost" FLOAT,
    "FM handling" FLOAT,
    "LM Handling" FLOAT,
    "MM Handling" FLOAT,
    "Handling Cost" FLOAT,
    "Common Costs" FLOAT,
    "Demurrage Charges" FLOAT,
    "Delivery reattempt Charges" VARCHAR,
    "CN%" FLOAT,
    "Credit Notes" FLOAT,
    "Other Costs" FLOAT,
    "Total Cost" FLOAT,
    "Margin" FLOAT,
    "MM Cost%" FLOAT,
    "Del Date" VARCHAR,
    "Del Date2" TIMESTAMP_TZ,
    "Flag" VARCHAR,
    "Vol FT3" FLOAT,
    "merge1" FLOAT,
    "TOT_PHYWT" FLOAT,
    "TOT_VOLWT" FLOAT,
    "MPS_COUNT" FLOAT,
    "CLIENTID" FLOAT,
    "STATUS" VARCHAR,
    "PHYWEIGHT" FLOAT,
    "VOLWEIGHT" FLOAT,
    "TOT_CHRGWT" FLOAT,
    "Billable_CFT" FLOAT,
    "Density" FLOAT,
    "MEDIAN_DENSITY" FLOAT,
    "Calculated_CFT" FLOAT,
    "Calculated_CFT_CAPPED" FLOAT,
    "CFT_Hybrid" FLOAT,
    "Origin_City" VARCHAR,
    "Origin_Terr" VARCHAR,
    "Dest_City" VARCHAR,
    "Dest_Terr" VARCHAR,
    "PICKUPDATE" TIMESTAMP_TZ,
    "Density Bucket" VARCHAR,
    "Client Group" VARCHAR,
    "Territory" VARCHAR,
    "TSM.Name" VARCHAR,
    "Zone" VARCHAR,
    "ZSM.Name" VARCHAR
);

CREATE TABLE AWB_FILE (
    "parentawbno" VARCHAR,
    "pdd" TIMESTAMP_TZ
);

CREATE TABLE FM_JOURNEY (
    "AWB" VARCHAR,
    "PICKUPDATE" TIMESTAMP_TZ,
    "FM_TRIPID" FLOAT,
    "ORIGINHUB" VARCHAR,
    "PICKUPPINCODE" FLOAT,
    "ODA/NORMAL" VARCHAR
);

CREATE TABLE LM_JOURNEY (
    "AWB" VARCHAR,
    "RADDATE" TIMESTAMP_TZ,
    "LM_TRIPID" FLOAT,
    "DESTHUB" VARCHAR,
    "ISMALLDELIVERY" VARCHAR,
    "TOTALATTEMPTCOUNT" FLOAT,
    "DELIVERYDATETIME" TIMESTAMP_TZ,
    "DELIVERYPINCODE" FLOAT,
    "ODA/NORMAL" VARCHAR,
    "APPT/NORMAL" VARCHAR
);

CREATE TABLE MM_JOURNEY (
    "TRIP ORDER" FLOAT,
    "AWB" VARCHAR,
    "CONNECTIONTYPE" VARCHAR,
    "MM_TRIPID" FLOAT,
    "CONNECTIONID" FLOAT,
    "CONNECTIONSCHEDULEMASTERID" FLOAT,
    "DEPART_LOCATION (Loading)" VARCHAR,
    "ARRIVAL_LOCATION (UnLoading)" VARCHAR
);

CREATE TABLE DAILY_LOAD (
    "row_num" VARCHAR,
    "stoppointorder" FLOAT,
    "connectionid" VARCHAR,
    "AWB" VARCHAR,
    "TRIP ORDER" FLOAT,
    "MM_TRIPID" FLOAT,
    "CLIENTID" VARCHAR,
    "CLIENTNAME" VARCHAR,
    "MPS_COUNT" FLOAT,
    "TOT_PHYWT" FLOAT,
    "TOT_VOLWT" FLOAT,
    "TOT_CHRGWT" FLOAT,
    "STOPPOINTHUBNAME" VARCHAR,
    "Departure_time_stoppointhub" VARCHAR,
    "final_connection_name" VARCHAR,
    "Loading_city" VARCHAR,
    "Unloading_city" VARCHAR,
    "DEPART_LOCATION (Loading)" VARCHAR,
    "ARRIVAL_LOCATION (UnLoading)" VARCHAR,
    "Trip_start_date" TIMESTAMP_TZ,
    "Trip_close_date" TIMESTAMP_TZ,
    "LH Cost" FLOAT,
    "PICKUPDATE" TIMESTAMP_TZ,
    "ORIGINHUB" VARCHAR,
    "DELIVERYDATETIME" TIMESTAMP_TZ,
    "DESTHUB" VARCHAR,
    "FULLCONNECTIONNAME" VARCHAR,
    "CONNECTIONENDHUB" VARCHAR,
    "CONNECTIONSTARTHUB" VARCHAR
);

CREATE TABLE WEIGHTED_UTILIZATION (
    "Start Date" VARCHAR,
    "Close Date" VARCHAR,
    "connectionid" VARCHAR,
    "TripSheetNo" VARCHAR,
    "stoppointorder" VARCHAR,
    "Final connection name" VARCHAR,
    "Lane" VARCHAR,
    "route_type" VARCHAR,
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
    "Phy wt Ecomm_IGN" VARCHAR,
    "Phy wt Cargo_IGN" VARCHAR,
    "Vol wt Ecomm_IGN" VARCHAR,
    "Vol wt Cargo_IGN" VARCHAR,
    "Phy Cap_IGN" VARCHAR,
    "Vol Cap_IGN" VARCHAR,
    "Chg Cap_IGN" VARCHAR,
    "Phy Wt_IGN" VARCHAR,
    "Vol Wt_IGN" VARCHAR,
    "Chg Wt_IGN" VARCHAR,
    "Vendor_Name" VARCHAR,
    "Start" VARCHAR,
    "Close" VARCHAR,
    "Dedicated Route as per Mapping" VARCHAR,
    "Cost_sharing" VARCHAR,
    "New_trip_cost" VARCHAR,
    "Vehicle_Volume" VARCHAR,
    "vehicle_hired" VARCHAR,
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
    "route mode" VARCHAR
);

CREATE TABLE IF NOT EXISTS DIM_HUB_CITY (
    "HubName" VARCHAR,
    "HubState" VARCHAR,
    "HubCity" VARCHAR,
    "Territory" VARCHAR
);

CREATE TABLE IF NOT EXISTS DIM_HUB_TO_ZONE (
    "hubid" VARCHAR,
    "hubname" VARCHAR,
    "hubzoneid" VARCHAR,
    "hubzonename" VARCHAR,
    "centertype" VARCHAR,
    "isactive" VARCHAR
);

CREATE TABLE IF NOT EXISTS DOC_CHUNKS (
    DOC_NAME VARCHAR,
    CHUNK_ID NUMBER(38,0),
    CHUNK_TEXT VARCHAR
);
