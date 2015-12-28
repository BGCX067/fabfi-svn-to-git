-- phpMyAdmin SQL Dump
-- version 3.3.10deb1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Nov 14, 2011 at 10:14 AM
-- Server version: 5.1.54
-- PHP Version: 5.3.5-1ubuntu7.3

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `meshmib`
--

-- --------------------------------------------------------

--
-- Table structure for table `fabfinumber_ip`
--

CREATE TABLE IF NOT EXISTS `fabfinumber_ip` (
  `index` int(11) NOT NULL AUTO_INCREMENT,
  `node_number` int(11) NOT NULL,
  `IP_address` varchar(30) NOT NULL,
  PRIMARY KEY (`index`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `links`
--

CREATE TABLE IF NOT EXISTS `links` (
  `index` int(11) NOT NULL AUTO_INCREMENT,
  `source_ip` varchar(36) NOT NULL,
  `dest_ip` varchar(36) NOT NULL,
  `lq` float NOT NULL,
  `nlq` float NOT NULL,
  `cost` float NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`index`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=83981 ;

-- --------------------------------------------------------

--
-- Table structure for table `node`
--

CREATE TABLE IF NOT EXISTS `node` (
  `fabfi_number` int(11) NOT NULL,
  `ipv6_address` varchar(30) NOT NULL,
  `type` char(1) NOT NULL,
  `latitude` double NOT NULL,
  `longitude` double NOT NULL,
  `cacti_index` int(11) NOT NULL,
  `node_info` mediumtext NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`fabfi_number`),
  UNIQUE KEY `ipv6_address` (`ipv6_address`),
  UNIQUE KEY `ipv6_address_2` (`ipv6_address`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `node_neighbours`
--

CREATE TABLE IF NOT EXISTS `node_neighbours` (
  `neigh_ip` varchar(30) NOT NULL,
  `neigh_cacti_index` int(11) NOT NULL,
  `lq` float NOT NULL,
  `nlq` float NOT NULL,
  `cost` float NOT NULL,
  `latitude` float NOT NULL,
  `longitude` float NOT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `olsr_updates`
--

CREATE TABLE IF NOT EXISTS `olsr_updates` (
  `index` int(11) NOT NULL AUTO_INCREMENT,
  `local_ip` float NOT NULL,
  `remote_ip` float NOT NULL,
  `lq` float NOT NULL,
  `nlq` float NOT NULL,
  `cost` float NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`index`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;
