#Wordcount across headlines
head <- read.table('Headlines_1955_2009_wordcount.txt', header=F, sep='\t')
names(head) <- c('Date','Headline','Wordcount')
head$Date <- strptime(head$Date, '%Y%m%d')
head$Month <- strftime(head$Date, '%m')
head$Year <- strftime(head$Date, '%Y')
head$Decade <- as.factor(paste(substr(head$Year,1,3),'0s',sep=''))

#Frequency of words and tags
words <- read.csv('Word_tag_frequency.csv', header=F)
names(words) <- c('Year','Word','Tag','freq')
sortyear <- c()
for (year in 1955:2009){
  stryear <- as.character(year)
  temp <- words[words$Year==year,]
  sorted <- cbind(data.frame(year),
                  c(1:nrow(temp)),
                  temp[order(-temp$freq),]$freq)
  cuml <- vector()
  for (i in 1:nrow(sorted)){ 
    if(i==1)
      cuml[i] <- (sorted[i,3]/sum(sorted[,3]))*100
    else {
      k = i-1
      cuml[i] <- (sorted[i,3]/sum(sorted[,3]))*100 + cuml[k]
    }
  }
  sorted$cuml <- cuml
  sortyear[[year]] <- sorted
}
sortyear <- data.frame(do.call('rbind',sortyear))
names(sortyear) <- c('year','index','freq','cuml')
sortyear$decade <- paste(substr(sortyear$year,1,3),'0s',sep='')

library(data.table)

#Wordcount across headlines
headt <- data.table(head)
month <- headt[,list(mean(Wordcount),count=.N),
               by=list(Decade,Year,Month)]
year <- headt[,list(mean(Wordcount),count=.N),
              by=list(Decade,Year)]
decade <- headt[,list(mean(Wordcount),avcount=.N/10),
                by=Decade]
monthlist <- factor(month$Month, labels=c('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'))

#Tagcount across headlines
wordsdt <- data.table(words)
wordsdt$Tagg <- substr(wordsdt$Tag,1,2)
tagyear <- wordsdt[,list(Tagcount=sum(freq),),
                   by=list(Year,Tagg)]
tagyear <- data.frame(tagyear)
tagyear$Decade <- paste(substr(tagyear$Year,1,3),'0s',sep='')

#merge 'what-how' tags
wh <- c('WR','WP','WD','WH')
newtag <- c()
for (year in 1955:2009){
  decade <- paste(substr(as.character(year),1,3),'0s',sep='')
  aa <- tagyear[tagyear$Tagg %in% wh & tagyear$Year==year,]
  aa <- c(year,'WH',sum(aa[,3]),decade)
  newtag[[year]] <- rbind(tagyear[!(tagyear$Tagg %in% wh) & tagyear$Year==year,],aa)
}
newtag <- data.frame(do.call('rbind',newtag))

# remove uninformative tags
goodtag <- c('NN','JJ','VB','PR','IN','RB','MD','DT','CC','TO','RP','WH')
goodtagyear <- newtag[newtag$Tagg %in% goodtag,]
actag <- c('noun','adjective','verb','pronoun','preposition','adverb','modal auxillary','determiner',
           'conjunction','to','particle','what-how')
goodtagyear$AcTag <- 0
for (i in 1:length(goodtag)){
  goodtagyear[goodtagyear$Tagg==goodtag[i],]$AcTag <- actag[i]
}

#Calculate percentages, order tags consistently
ordertag <- c()
goodtagyear$Tagcount <- as.numeric(goodtagyear$Tagcount)
ordertag <- c('noun','verb','adjective','preposition','adverb','determiner','to','pronoun','modal auxillary',
              'conjunction','particle','what-how')
finaltag <- c()
for (year in 1955:2009){
  temp <- goodtagyear[goodtagyear$Year==year,]
  temp$Percent <- temp$Tagcount/sum(temp$Tagcount)*100
  temp$TagOrder <- 0
  for (i in 1:length(ordertag)){
    temp[temp$AcTag==ordertag[i],'TagOrder'] <- i
    temp <- temp[order(temp$TagOrder),]
    finaltag[[year]] <- temp 
  }
}
finaltag <- data.frame(do.call('rbind',finaltag))

#Plots
library(ggplot2)
library(RColorBrewer)
library(gridExtra)

pal <- brewer.pal(6,'Set1')
theme_mine <- function(base_size = 10, base_family = "Helvetica") {
  # Starts with theme_grey and then modify some parts
  theme_grey(base_size = base_size, base_family = base_family) %+replace%
    theme(
      axis.line   	= element_line(size=0.5, colour="black"),
      #axis.line 		= element_blank(),
      #axis.line.x		= element_line(size=0.5, colour="black"),
      #axis.line.y		= element_blank(),
      plot.title		= element_text(size = 20, colour="black", face="bold"),
      strip.text.x 		= element_text(size=18, colour="black", face= "bold"),
      strip.text.y 		= element_text(size=18, face="bold", angle=90),
      strip.background 	= element_rect(colour="white", fill="#CCCCCC"),
      axis.text.x		= element_text(size = 18, colour="black"),
      #axis.text.x		= element_blank(),
      axis.text.y		= element_text(size = 18, colour="black", vjust=0.5, hjust=1),
      #axis.text.y		= element_blank(),
      axis.title.x		= element_text(size=18, colour="black"),
      #axis.title.x		= element_blank(),
      #axis.title.y		= element_blank(),
      axis.title.y		= element_text(size=18, colour="black", angle=90),
      #axis.ticks       = element_blanks(),
      axis.ticks		= element_line(colour='black'),
      legend.key        = element_blank(),
      legend.background = element_blank(),
      legend.key.size	= unit(1.5, "lines"),
      legend.text		= element_text(size= rel(1.6)),
      #legend.title		= element_text(size= rel(1.6), face="bold"),
      legend.title		= element_blank(),
      legend.position	= 'none',
      panel.background  = element_blank(),
      panel.border      = element_blank(),
      plot.background	= element_blank(),	
      panel.grid.major  = element_blank(),
      panel.grid.minor  = element_blank(),
      plot.margin		= unit(c(1.5,1.5,1.5,1.5), "lines")
    )
}

#Histogram of wordcount
aa <- ggplot(head)
aa1 <- aa + geom_bar(aes(x=Wordcount), fill='grey', stat='bin')
aa2 <- aa1 + theme_mine() + scale_x_continuous(expand=c(0,0)) + scale_y_continuous(expand=c(0,0))
aa3 <- aa2 + ggtitle('Histogram of wordcount per headline, all years') + ylab('Frequency') + xlab('Wordcount')

#Average no. of words by year
bb <- ggplot(year)
bb1 <- bb + geom_bar(aes(x=Year,y=V1), fill='#0000CC', stat='identity')
bb2 <- bb1 + theme_mine() + scale_x_discrete(breaks=c(seq(1955,2009,5),2009)) + scale_y_continuous(expand=c(0,0))
bb3 <- bb2 + ylab('Average wordcount') + ggtitle('Average wordcount per headline, by year')

#Total no. of headlines, by year
cc1 <- bb + geom_bar(aes(x=Year,y=count), fill='#990000', stat='identity')
cc2 <- cc1 + theme_mine() + scale_x_discrete(breaks=c(seq(1955,2009,5),2009)) + scale_y_continuous(expand=c(0,0))
cc3 <- cc2 + ylab('Frequency') + ggtitle('Total no. of headlines, by year')

#Average no. of words by month and year
month$Decade <- as.factor(month$Decade)
month$Month <- as.factor(month$Month)
dd <- ggplot(month,aes(group=Year))
dd1 <- dd + geom_line(aes(x=monthlist,y=V1,colour=Decade), size=0.8, stat='smooth')
dd2 <- dd1 + theme_mine() + theme(legend.position='bottom') + scale_y_continuous(expand=c(0,0), limits=c(0,8)) + scale_colour_manual(values=pal)
dd3 <- dd2 + xlab('Month') + ylab('Average wordcount') + ggtitle('Average wordcount per headline, by month and year')

#Total no.of words by month and decade
ee <- ggplot(month,aes(group=Decade))
ee1 <- ee + geom_bar(aes(x=monthlist,y=count,fill=Decade), position='stack', stat='identity')
ee2 <- ee1 + theme_mine() + theme(legend.position='right') + scale_y_continuous(expand=c(0,0)) + scale_fill_manual(values=pal)
ee3 <- ee2 + xlab('Month') + ylab('Frequency') + ggtitle('Total no. of headlines, by month and decade')

#Plot all charts
grid.arrange(aa3,bb3,cc3,dd3,ee3, ncol=2)

#Word index, sorted by frequency and plotted against cumulative %

ff <- ggplot(sortyear,aes(group=factor(year)))
ff1 <- ff + geom_line(aes(x=index,y=cuml,colour=factor(decade)), size=0.7, alpha=0.6)
ff2 <- ff1 + theme_mine() + theme(legend.position=c(0.8,0.5)) + scale_colour_manual(values=pal)
ff3 <- ff2 + geom_hline(yintercept=90, linetype=2) + scale_y_continuous(breaks=c(0,25,50,75,90,100))
ff4 <- ff3 + xlab('word index') + ylab('cumulative %') + ggtitle('Number of top words covering 90% of wordcount in headlines ')

#Tags, by year
gg <- ggplot(finaltag,aes(group=factor(TagOrder)))
gg1 <- gg + geom_area(aes(x=Year,y=Percent,fill=factor(TagOrder, labels=ordertag)), position='stack', stat='identity')
gg2 <- gg1 + theme_mine() + theme(axis.text.x=element_text(angle=60),
                                  legend.position='right') 
gg3 <- gg2 + scale_fill_manual(values=brewer.pal(12,'Paired')) + scale_y_continuous(expand=c(0,0))
gg3 + ggtitle('Percentage breakdown of Part-of-Speech elements in headline words, by year')


