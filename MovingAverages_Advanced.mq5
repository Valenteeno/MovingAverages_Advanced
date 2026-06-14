//+------------------------------------------------------------------+
//|                               MovingAverages_Advanced_Optimized.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_label1  "Label1"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  DeepSkyBlue,PaleVioletRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

enum enumAveragesType
{
   avgSma,    // Simple moving average
   avgEma,    // Exponential moving average
   avgSmma,   // Smoothed moving average
   avgLwma,   // Linear weighted moving average
   avgLsma,   // Linear regression value
   avgTrima,  // Triangular moving average
   avgSwma,   // Sine weighted moving average
   avgHullma, // Hull moving average
   avgT3ma,   // T3 moving average
   avgQuant   // Qunatiles
};

input ENUM_TIMEFRAMES    TimeFrame     = PERIOD_CURRENT; // Time frame
input ENUM_APPLIED_PRICE Price         = PRICE_CLOSE;    // Apply to 
input int                AveragePeriod = 14;             // Calculation period
input enumAveragesType   AverageType   = 0;              // Calculation type
input string             _             = "";             // T3 parameters (used only if T3 chosen)
input double             T3Hot         = 0.7;            // T3 hot value
input bool               T3Original    = false;          // T3 original Tillson calculation?
input string             __            = "";             // Quantile parameters (used only if Quantiles chosen)
input double             QuantPercent  = 50.0;           // Quantile percent (50 == Median)
input bool               Multicolor    = true;           // Multi color mode?
input bool               Interpolate   = true;           // Interpolate mtf data ?

double MaBuffer[], ColorBuffer[], CountBuffer[];
enumAveragesType gAverageType;
ENUM_TIMEFRAMES timeFrame;
int mtfHandle, priceHandle;
bool calculating;

//+------------------------------------------------------------------+
int OnInit() {
   SetIndexBuffer(0,MaBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,CountBuffer,INDICATOR_CALCULATIONS); 
   gAverageType = AverageType;
   
   timeFrame = MathMax(_Period,TimeFrame);
   calculating = (timeFrame==_Period);
   
   if(!calculating) {
      string name = getIndicatorName(); 
      mtfHandle = iCustom(NULL,timeFrame,name,PERIOD_CURRENT,Price,AveragePeriod,AverageType,"",T3Hot,T3Original,"",QuantPercent,Multicolor);
      if(mtfHandle == INVALID_HANDLE) {
         Print("Failed to create MTF indicator handle");
         return(INIT_FAILED);
      }
   }
   
   // Create handle for price data
   priceHandle = iMA(_Symbol,_Period,1,0,MODE_SMA,Price);
   if(priceHandle == INVALID_HANDLE) {
      Print("Failed to create price handle");
      return(INIT_FAILED);
   }
   
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,AveragePeriod);
   PlotIndexSetString(0,PLOT_LABEL,getAverageName(gAverageType)+" ("+(string)AveragePeriod+")");
   IndicatorSetString(INDICATOR_SHORTNAME,getAverageName(gAverageType)+" ("+(string)AveragePeriod+")");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   int start_pos = prev_calculated;
   if(prev_calculated == 0) {
      start_pos = 0;
      ArrayInitialize(MaBuffer, EMPTY_VALUE);
      ArrayInitialize(ColorBuffer, 0);
      ArrayInitialize(CountBuffer, 0);
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,AveragePeriod+begin);
   }

   if(calculating) {      
      static averages caverage; 
      if(AverageType==avgT3ma && !caverage.T3Initialized) caverage.setT3Parameters(AveragePeriod,T3Hot,T3Original);
      if(AverageType==avgQuant && !caverage.QuantInitialized) caverage.setQuantParameters(QuantPercent);
      
      for(int i=(int)MathMax(start_pos-1,0); i<rates_total && !IsStopped(); i++) {
         MaBuffer[i] = caverage.calc(NULL,0,AveragePeriod,gAverageType,price[i],i);
         if(Multicolor && i>0) {
            ColorBuffer[i] = ColorBuffer[i-1];
            if(MaBuffer[i]>MaBuffer[i-1]) ColorBuffer[i]=0;
            if(MaBuffer[i]<MaBuffer[i-1]) ColorBuffer[i]=1;
         } else ColorBuffer[i]=0;
      }
      CountBuffer[rates_total-1] = MathMax(rates_total-start_pos+1,1);
      return(rates_total);
   }
   
   // MTF Processing
   if(mtfHandle == INVALID_HANDLE) {
      Print("Invalid MTF handle, trying to recreate...");
      string name = getIndicatorName();
      mtfHandle = iCustom(NULL,timeFrame,name,PERIOD_CURRENT,Price,AveragePeriod,AverageType,"",T3Hot,T3Original,"",QuantPercent,Multicolor);
      if(mtfHandle == INVALID_HANDLE) {
         Print("Failed to recreate MTF handle");
         return(prev_calculated);
      }
   }
   
   datetime times[];
   int bars = CopyTime(NULL,timeFrame,0,rates_total*2,times);
   if(bars <= 0) {
      Print("Failed to copy time data");
      return(prev_calculated);
   }
   
   double values[], colors[], counts[];
   int val_copied = CopyBuffer(mtfHandle,0,0,bars,values);
   int col_copied = CopyBuffer(mtfHandle,1,0,bars,colors);
   int cnt_copied = CopyBuffer(mtfHandle,2,0,bars,counts);
   
   if(val_copied <= 0 || col_copied <= 0 || cnt_copied <= 0) {
      Print("Failed to copy MTF buffers");
      return(prev_calculated);
   }
   
   datetime currentTimes[];
   CopyTime(_Symbol,_Period,0,rates_total,currentTimes);
   
   double count_factor = (bars>0 && counts[bars-1]>0) ? counts[bars-1] : 1;
   int maxb = (int)MathMax(MathMin(count_factor*PeriodSeconds(timeFrame)/PeriodSeconds(Period()),rates_total-1),1);

   for(int i=(int)MathMax(start_pos-maxb,0); i<rates_total && !IsStopped(); i++) {
      int d = dateArrayBsearch(times,currentTimes[i],bars);
      if(d>-1 && d<bars && d<ArraySize(values)) {
         if(values[d]!=EMPTY_VALUE) {
            MaBuffer[i] = values[d];
            ColorBuffer[i] = (d<ArraySize(colors)) ? colors[d] : 0;
         } else if(i>0 && MaBuffer[i-1]!=EMPTY_VALUE) {
            MaBuffer[i] = MaBuffer[i-1];
            ColorBuffer[i] = ColorBuffer[i-1];
         }
      } else if(i>0 && MaBuffer[i-1]!=EMPTY_VALUE) {
         MaBuffer[i] = MaBuffer[i-1];
         ColorBuffer[i] = ColorBuffer[i-1];
      }
      
      if(!Interpolate) continue;
      
      int l=MathMin(i+1,rates_total-1);
      if(d!=dateArrayBsearch(times,currentTimes[l],bars) || i==l) {
         int n,k;
         for(n=1; (i-n)>0 && currentTimes[i-n]>=times[d]; n++) continue;	
         for(k=1; (i-k)>=0 && k<n; k++) {
            if((i-n)>=0 && MaBuffer[i-n]!=EMPTY_VALUE && MaBuffer[i]!=EMPTY_VALUE) {
               MaBuffer[i-k] = MaBuffer[i]+(MaBuffer[i-n]-MaBuffer[i])*k/n;
               if(Multicolor && k>1) {
                  if(MaBuffer[i-k]>MaBuffer[i-k+1]) ColorBuffer[i-k]=0;
                  else if(MaBuffer[i-k]<MaBuffer[i-k+1]) ColorBuffer[i-k]=1;
                  else ColorBuffer[i-k]=ColorBuffer[i-k+1];
               }
            }
         }
      }
   }
   return(rates_total);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   if(mtfHandle != INVALID_HANDLE) {
      IndicatorRelease(mtfHandle);
      mtfHandle = INVALID_HANDLE;
   }
   if(priceHandle != INVALID_HANDLE) {
      IndicatorRelease(priceHandle);
      priceHandle = INVALID_HANDLE;
   }
}

//+------------------------------------------------------------------+
int dateArrayBsearch(datetime& times[], datetime toFind, int total) {
   if(total<=0 || ArraySize(times)==0) return -1;
   int mid=0, first=0, last=total-1;
   if(toFind<=times[0]) return 0;
   if(toFind>=times[last]) return last;
   while(last>=first) {
      mid = (first+last)>>1;
      if(toFind==times[mid] || (mid<(total-1) && (toFind>times[mid]) && (toFind<times[mid+1]))) break;
      if(toFind<times[mid]) last = mid-1;
      else first = mid+1;
   }
   return MathMax(MathMin(mid,total-1),0);
}

//+------------------------------------------------------------------+
string getIndicatorName() {
   string progPath = MQL5InfoString(MQL5_PROGRAM_PATH);
   string termPath = TerminalInfoString(TERMINAL_PATH);
   int startLength = StringLen(termPath)+17;
   string indicatorName = StringSubstr(progPath,startLength);
   indicatorName = StringSubstr(indicatorName,0,StringLen(indicatorName)-4);
   return indicatorName;
}

//+------------------------------------------------------------------+
string methodNames[] = {"Simple MA","Exponential MA","Smoothed MA","Linear weighted MA",
                        "Linear regression value","Triangular MA","Sine weighted MA",
                        "Hull MA","T3 MA","Quantile"};
string getAverageName(enumAveragesType& method) {
   method=MathMax(MathMin(method,9),0); 
   return methodNames[method];
}

//+------------------------------------------------------------------+
class averages {
   protected:
      double aResultBuffer[];
      double aPricesBuffer[];
      double t3c1,t3c2,t3c3,t3c4,t3period;
      bool t3Original;
      double quantPercent;
   public:
      bool T3Initialized, QuantInitialized;
      void averages() { T3Initialized=false; QuantInitialized=false; };
      double calc(string symbol, ENUM_TIMEFRAMES period, double cPeriod, int cType, double cPrice, int i);
      void setT3Parameters(double cPeriod, double cT3Hot, bool cT3Original);
      void setQuantParameters(double cPercent);
};

//+------------------------------------------------------------------+
void averages::setQuantParameters(double cPercent) {
   quantPercent = MathMax(MathMin(cPercent,100),0);
   QuantInitialized = true;            
}

void averages::setT3Parameters(double cPeriod, double cT3Hot, bool cT3Original) {
   cT3Hot = MathMax(MathMin(cT3Hot,1),0.0001);
   double a = cT3Hot;
   t3c1 = -a*a*a;
   t3c2 = 3*(a*a+a*a*a);
   t3c3 = -3*(2*a*a+a+a*a*a);
   t3c4 = 1+3*a+a*a*a+3*a*a;
   t3period = cPeriod; 
   if(!cT3Original) t3period = 1.0+(t3period-1.0)/2.0;
   T3Initialized = true;            
}

//+------------------------------------------------------------------+
double averages::calc(string symbol, ENUM_TIMEFRAMES period, double cPeriod, int cType, double cPrice, int i) {
   if(symbol==NULL) symbol = _Symbol;
   if(period==0) period = _Period;
   if(cPeriod<=0 || i<0) return EMPTY_VALUE;
   
   int bars = Bars(symbol,period);
   if(bars<=0 || i>=bars) return EMPTY_VALUE;
   
   if(ArrayRange(aPricesBuffer,0)!=bars) ArrayResize(aPricesBuffer,bars);
   if(i<ArraySize(aPricesBuffer)) aPricesBuffer[i] = cPrice;
   
   switch(cType) {
      case avgSma: {
         double avg=0; int k;
         for(k=0; k<cPeriod && (i-k)>=0 && (i-k)<ArraySize(aPricesBuffer); k++) avg += aPricesBuffer[i-k];
         return (k>0) ? avg/k : EMPTY_VALUE;
      }
      
      case avgEma: {
         if(ArrayRange(aResultBuffer,0)!=bars) ArrayResize(aResultBuffer,bars);
         if(i>0 && (i-1)<ArraySize(aResultBuffer) && i<ArraySize(aResultBuffer))
            aResultBuffer[i] = aResultBuffer[i-1]+(2/(cPeriod+1))*(cPrice-aResultBuffer[i-1]);
         else if(i<ArraySize(aResultBuffer) && i<ArraySize(aPricesBuffer))
            aResultBuffer[i] = aPricesBuffer[i];
         else return EMPTY_VALUE;
         return aResultBuffer[i];
      }
      
      case avgSmma: {
         if(ArrayRange(aResultBuffer,0)!=bars) ArrayResize(aResultBuffer,bars);
         if(i<=cPeriod) {
            double avg=0; int k;
            for(k=0; k<cPeriod && (i-k)>=0 && (i-k)<ArraySize(aPricesBuffer); k++) avg += aPricesBuffer[i-k];
            if(k>0 && i<ArraySize(aResultBuffer)) aResultBuffer[i] = avg/k;
            else if(i<ArraySize(aResultBuffer) && i<ArraySize(aPricesBuffer)) aResultBuffer[i] = aPricesBuffer[i];
            else return EMPTY_VALUE;
         } else if((i-1)<ArraySize(aResultBuffer) && i<ArraySize(aResultBuffer) && i<ArraySize(aPricesBuffer)) {
            aResultBuffer[i] = (aResultBuffer[i-1]*(cPeriod-1)+aPricesBuffer[i])/cPeriod;
         } else return EMPTY_VALUE;
         return aResultBuffer[i];
      }
      
      case avgLwma: {
         double sum=0, sumw=0;
         for(int k=0; k<cPeriod && (i-k)>=0 && (i-k)<ArraySize(aPricesBuffer); k++) {
            double weight = cPeriod-k;
            sumw += weight;
            sum += weight*aPricesBuffer[i-k];
         }
         return (sumw!=0) ? sum/sumw : EMPTY_VALUE;
      }
      
      case avgLsma: {
         static averages lwma;
         static averages sma;
         return (3*lwma.calc(symbol,period,cPeriod,avgLwma,cPrice,i)-2*sma.calc(symbol,period,cPeriod,avgSma,cPrice,i));
      }
      
      case avgTrima: {
         double half = (cPeriod+1.0)/2.0;
         double sum=0, sumw=0;
         for(int k=0; k<cPeriod && (i-k)>=0 && (i-k)<ArraySize(aPricesBuffer); k++) {
            double weight = cPeriod-k; 
            if(weight>half) weight = half;
            sumw += weight;
            sum += weight*aPricesBuffer[i-k];
         }
         return (sumw!=0) ? sum/sumw : EMPTY_VALUE;
      }
      
      case avgSwma: {
         #define Pi 3.14159265358979323846
         double sum=0, sumw=0;
         for(int k=0; k<cPeriod && (i-k)>=0 && (i-k)<ArraySize(aPricesBuffer); k++) {
            double weight = MathSin(Pi*(k+1)/(cPeriod+1));
            sumw += weight;
            sum += weight*aPricesBuffer[i-k];
         }
         return (sumw!=0) ? sum/sumw : EMPTY_VALUE;
      }
      
      case avgHullma: {
         int HalfPeriod = (int)MathFloor(cPeriod/2);
         int HullPeriod = (int)MathFloor(MathSqrt(cPeriod));
         static averages lwma1;
         static averages lwma2;
         static averages lwma3;
         double price1 = lwma1.calc(symbol,period,HalfPeriod,avgLwma,cPrice,i)*2-lwma2.calc(symbol,period,cPeriod,avgLwma,cPrice,i);
         return lwma3.calc(symbol,period,HullPeriod,avgLwma,price1,i);
      }
      
      case avgQuant: {
         static double quantileArray[];
         if(ArraySize(quantileArray)!=cPeriod) ArrayResize(quantileArray,(int)cPeriod);
         int validArrayCount=0;
         for(int k=0; k<cPeriod && (i-k)>=0 && (i-k)<ArraySize(aPricesBuffer) && validArrayCount<ArraySize(quantileArray); k++) {
            quantileArray[validArrayCount] = aPricesBuffer[i-k];
            validArrayCount++;
         }
         if(validArrayCount==0) return EMPTY_VALUE;
         ArraySort(quantileArray);
         double index = (validArrayCount-1)*quantPercent/100.0;
         int ind = (int)index;
         double delta = index-ind;
         if(ind>=validArrayCount) ind = validArrayCount-1;
         if(ind<0) ind = 0;
         if(ind==NormalizeDouble(index,5) || (ind+1)>=validArrayCount) return quantileArray[ind];
         else return (1.0-delta)*quantileArray[ind]+delta*quantileArray[ind+1];
      }
      
      case avgT3ma: {
         static averages ema1; double price1 = ema1.calc(symbol,period,t3period,avgEma,cPrice,i);
         static averages ema2; double price2 = ema2.calc(symbol,period,t3period,avgEma,price1,i);
         static averages ema3; double price3 = ema3.calc(symbol,period,t3period,avgEma,price2,i);
         static averages ema4; double price4 = ema4.calc(symbol,period,t3period,avgEma,price3,i);
         static averages ema5; double price5 = ema5.calc(symbol,period,t3period,avgEma,price4,i);
         static averages ema6; double price6 = ema6.calc(symbol,period,t3period,avgEma,price5,i);
         return t3c1*price6+t3c2*price5+t3c3*price4+t3c4*price3;
      }
   }
   return EMPTY_VALUE;
}
//+------------------------------------------------------------------+