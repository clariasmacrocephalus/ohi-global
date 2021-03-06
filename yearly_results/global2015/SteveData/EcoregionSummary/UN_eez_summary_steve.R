#################################################
## Summarizing OHI 2015 scores using color scheme I used for continental scale
## Steve K. request 1/22/2016
#################################################
library(tidyr)
library(dplyr)
library(sp)
library(rgdal)
library(RColorBrewer)
library(ohicore)
library(DT)
library(ggplot2)


############################################
## Map of Index scores

# some organization of data
goals <- c('Index', 'AO', 'SPP', 'BD', 'HAB', 'CP', 'CS', 'CW', 'ECO', 'LE', 'LIV', 'FIS', 'FP', 'MAR', 'ICO', 'SP', 'LSP', 'NP', 'TR')
goal_names <- data.frame(goal = goals, 
                         goal_name = c("Index", "Artisanal Fishing Opportunities", "Species", "Biodiversity", "Habitats",
                                       "Coastal Protection", "Carbon Storage", "Clean Waters", "Economies", "Coastal Livelihoods and Economies",
                                       "Livelihoods", "Fisheries", "Food Provision", "Mariculture", "Iconic Species", "Sense of Place",
                                       "Lasting Special Places", "Natural Products", "Tourism and Recreation"))

PlotData <- read.csv('eez2015/scores.csv') %>%
  filter(dimension == "score") %>%
  filter(region_id <= 250) %>%
  filter(region_id != 0) %>%
  select(code=region_id, goal, score) %>%
  left_join(goal_names) %>%
  mutate(goal = factor(goal_name, levels=goal_names$goal_name)) %>%
  select(-goal_name)

PlotData <- spread(PlotData, goal, score) 
rownames(PlotData) <- PlotData$code


## read in map data:
p <- readOGR(dsn='/var/data/ohi/model/GL-NCEAS-OceanRegions_v2013a/data', layer= 'rgn_ocean_cntry_mol')

## This isolates the main map parts: 
ocean  <-  p[is.na(p@data$ISO_3digit) & p@data$rgn_id==0,]
land  <-  p[!is.na(p@data$ISO_3digit) & p@data$rgn_id==0,]
rgnOHI <-  p[p@data$rgn_id>0,]


mapCols <- 2:ncol(PlotData)

# palette <- colorRampPalette(brewer.pal(9, 'YlOrRd'))
# palette <- palette(100)
# MyColor <- palette[col.brks] 

palette <- colorRampPalette(c("#F0731E", "#FFA028", "#F7C332", "#14AAC8", "#325AAA"))
palette <- palette(100)
MyColor <- palette[c(1, 8, 16, 24, 32, 45, 64, 73, 90, 100)] 
col.brks <-  c(0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100)

#col.brks <- c(0, 25, 50, 75, 90, 100)


## This loop goes through the columns to be plotted and:
## 1. matches the data row names (rgn_id) to the rgn_id of the OHI regions
## 2. identifies the break points for colors from: 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100
## 3. plots the maps and saves them to the "fig" file in the working directory 

for (i in 1:length(mapCols)){ 
  #i <- 1
  s=mapCols[i]
  # Index map
  fld = names(PlotData)[s]
  v= PlotData[match(rgnOHI@data$rgn_id, row.names(PlotData)), fld]    
  maps = setNames(list(v), fld)  
  
  fig = sprintf('global2015/SteveData/EcoregionSummary/rgnMaps/global_map_mol_%s.png', fld)
  
  
  # ensure color ramp breaks contain all data
  stopifnot(max(v,na.rm=T)<=max(col.brks) & min(v,na.rm=T)>=min(col.brks))
  
  # plot map
  png(file=fig, width=1200, height=800, res=150, pointsize=18, type='cairo')
  par(oma=c(0,0,0,0),
      mar=c(1.5,1,0,1))
  plot(ocean, col='gray90', border=NA)
  #plot(rgnOHI, border=brewer.pal(10, 'RdYlBu')[cut(v, col.brks, labels=1:10, include.lowest=TRUE)], add=TRUE,
  #     col=brewer.pal(10, 'RdYlBu')[cut(v, col.brks, labels=1:10, include.lowest=TRUE)])
  plot(rgnOHI, border="grey75", add=TRUE,
      col=MyColor[cut(v, col.brks, labels=1:10, include.lowest=TRUE)])
  
  plot(land, col='gray80', border='grey75', add=TRUE)
  
  # get plotting dimensions
  p=par('usr'); px=diff(p[1:2]); py=diff(p[3:4]) # c(x1, x2, y1, y2)
  
  # add label
  text(x=p[1]+px*0.02, y=p[4]-py*0.1, labels=fld, pos=4) # +p.dx*0.1
  
  # plot legend
  yh=0.05; x1=p[1]+px*0.2; x2=p[2]-px*0.2; y1=p[3]; y2=p[3]+py*yh
  #ix = seq(x1, x2, length.out=10)
  ix = seq(x1, x2, length.out=10)
  ixd = diff(ix)[1]/2
  par(xpd=TRUE) # turn off clipping to plot region
  image(x = ix,
        y = c(y1, y2),
        z = matrix(1:10), col=MyColor, add=TRUE)
        #z = matrix(1:10), col=brewer.pal(10, 'RdYlBu'), add=T)
  rect(x1-ixd,y1,x2+ixd,y2, border='gray20')
  rect(x1-ixd*3,y1,x1-ixd,y2, border='gray20')
  text(x = c(x1-ixd*2, seq(x1-ixd, x2+ixd, length.out=11)),
#  text(x = c(x1-ixd*2, seq(x1-ixd, x2+ixd, length.out=6)),
       y = y1, cex=0.6, pos=1, # adj=c(0.5,0), # , offset=0.1,
       labels=c('NA',as.character(col.brks))) 
  par(xpd=F) # turn back on clipping to plot region
  
  # finish fig
  dev.off() #; system(sprintf('open %s', fig))
}
