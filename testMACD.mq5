//+------------------------------------------------------------------+
//|                                                     testMACD.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <socket-library-mt4-mt5.mqh>

double         MACDBuffer[];
double         SignalBuffer[];
//--- variable for storing the handle of the iMACD indicator
int    handle;

input int                  fast_ema_period=12;        // period of fast ma
input int                  slow_ema_period=26;        // period of slow ma
input int                  signal_period=9;           // period of averaging of difference
input ENUM_APPLIED_PRICE   applied_price=PRICE_CLOSE; // type of price  
input string               symbol=" ";                // symbol 
input ENUM_TIMEFRAMES      period=PERIOD_M1;;     // timeframe
//--- variable for storing
string name=symbol;
//--- name of the indicator on a chart
string short_name;
//--- we will keep the number of values in the Moving Averages Convergence/Divergence indicator
int    bars_calculated=0;
ClientSocket *pNewClient=NULL;
ServerSocket *ssocket = NULL;

void establishConn()
{
  ServerSocket *socket = NULL;
   socket=new ServerSocket(9091, true);
   if (!socket.Created()) {
      Print("Port already in use.");
      return;
   }
   Print("Socket created.");
   while (true){
      pNewClient = socket.Accept();
      if (pNewClient) {
         break;
      }
      Sleep(1000);
   } 
}

int OnInit()
  {
   int err1=0;
   int err2=0;
   int err0=0;
   string out;
   int barnum;
   int indx;
   establishConn();
   while (1==1)
   {
      if(pNewClient.IsSocketConnected())
      {
         string msg=pNewClient.Receive();
    //     string sep=',';
         ushort u_sep=',';
         string result[];
    //     u_sep=StringGetCharacter(sep,0);
         if (StringLen(msg)<1)
         {
            Print("Failed to get data from client.");
            return(INIT_FAILED);
         }
         
         indx=StringSplit(msg,u_sep,result);
         if (indx>0)
         {
            name=result[0];
            Print ("Symbol:"+name);
            barnum=StringToInteger(result[1]);
            Print ("barnumber:",barnum);
         }
      }
      else
         return(INIT_FAILED);
      
      ArraySetAsSeries(MACDBuffer,true);
      ArraySetAsSeries(SignalBuffer,true);
      SetIndexBuffer(0,MACDBuffer,INDICATOR_DATA);
      SetIndexBuffer(1,SignalBuffer,INDICATOR_DATA);
   //--- determine the symbol the indicator is drawn for
    //  name=Symbol();
   //--- delete spaces to the right and to the left
      StringTrimRight(name);
      StringTrimLeft(name);
   //--- if it results in zero length of the 'name' string
      if(StringLen(name)==0)
        {
         //--- take the symbol of the chart the indicator is attached to
         name="EPM20";//_Symbol;
        }
        int digits=(int)SymbolInfoInteger(name,SYMBOL_DIGITS);
        Print("In Onit Hi How are You");
       handle=iMACD(name,period,fast_ema_period,slow_ema_period,signal_period,applied_price);
       
      if(handle==INVALID_HANDLE)
        {
         //--- tell about the failure and output the error code
         PrintFormat("Failed to create handle of the iMACD indicator for the symbol %s/%s, error code %d",
                     name,
                     GetLastError());
         //--- the indicator is stopped early
         return(INIT_FAILED);
        }
     datetime New_Time[1];
     int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
      if(copied>0) // ok, the data has been copied successfully
        {
        Print (New_Time[0]);
        }
     err1=CopyBuffer(handle,0,0,barnum,MACDBuffer);
     if (err1<0)
      {
      Print("Failed to copy data");
      return(INIT_FAILED);
      }
      ArrayPrint(MACDBuffer);
      
      err0=CopyBuffer(handle,1,0,barnum,SignalBuffer);
     if (err0<0)
      {
      Print("Failed to copy data");
      return(INIT_FAILED);
      }
      ArrayPrint(SignalBuffer);
      
      MqlRates mrate[];
      ArraySetAsSeries(mrate,true);
      
      err2=CopyRates(name,period,0,barnum,mrate);
      if(err2<0)
        {
         Alert("Error copying rates/history data - error:",GetLastError(),"!!");
         return(INIT_FAILED);
        }
      ArrayPrint(mrate);
      /*
      for(int i=0;i<10;i++)
      {
         Print(TimeToString(mrate[i].time)+","+DoubleToString(mrate[i].open,digits)+","+DoubleToString(mrate[i].high,digits)+","+DoubleToString(mrate[i].low,digits)+","+DoubleToString(mrate[i].close,digits)+","+DoubleToString(mrate[i].real_volume,0)+","+DoubleToString(MACDBuffer[i],2)+","+DoubleToString(SignalBuffer[i],2));
      }*/
      
       if(pNewClient.IsSocketConnected())
      {
         for(int i=0;i<barnum;i++)
         {
            out=TimeToString(mrate[i].time)+","+DoubleToString(mrate[i].open,2)+","+DoubleToString(mrate[i].high,2)+","+DoubleToString(mrate[i].low,2)+","+DoubleToString(mrate[i].close,2)+","+DoubleToString(mrate[i].real_volume,0)+","+DoubleToString(MACDBuffer[i],2)+","+DoubleToString(SignalBuffer[i],2)+"\n";
            Print(out);
            pNewClient.Send(out);
         }
         
      }
      else
         Print("Connection not up.Shutting down");
      
      return(INIT_SUCCEEDED);
   
   }
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
/*
   static datetime Old_Time;
   datetime New_Time[1];
   bool IsNewBar=false;
   int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
   if(copied>0) // ok, the data has been copied successfully
     {
      if(Old_Time!=New_Time[0]) // if old time isn't equal to new bar time
        {
         IsNewBar=true;   // if it isn't a first call, the new bar has appeared
//         if(MQL5InfoInteger(MQL5_DEBUGGING)) 
            Print("We have new bar here ",New_Time[0]," old time was ",Old_Time);
         Old_Time=New_Time[0];            // saving bar time
        }
     }
   else
     {
      Alert("Error in copying historical times data, error =",GetLastError());
      ResetLastError();
      return;
     }
     if(IsNewBar==false)
     {
      return;
     }
//     int Mybars=Bars(_Symbol,_Period);

     IsNewBar=false;
   int err1=0;
   err1=CopyBuffer(handle,0,0,10,MACDBuffer);
   if (err1<0)
   {
   Print("Failed to copy data");
   return;
   }
   ArrayPrint(MACDBuffer);
   if(pNewClient.IsSocketConnected())
   {
      pNewClient.Send(DoubleToString(MACDBuffer[0],1));
   }
   else
      Print("Connection not up.Shutting down");
   return;
   */
  }
//+------------------------------------------------------------------+

