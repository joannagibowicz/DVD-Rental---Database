use [Wypo�yczalnia Film�w]

-- tworzenie tabel --

if not exists (select 1 from INFORMATION_SCHEMA.TABLES WHERE TABLE_CATALOG = 'Wypo�yczalnia Film�w' and TABLE_NAME ='Film')
begin
		create table Film (
		FilmID int identity (1,1) primary key not null,
		Tytu� nvarchar (255) not null,
		GatunekFilmu nvarchar (50),
		Re�yser nvarchar (50),
		RokProdukcji int,
		KrajProdukcji nvarchar(50),
		KategoriaID int
)
end;

if not exists (select 1 from INFORMATION_SCHEMA.TABLES WHERE TABLE_CATALOG = 'Wypo�yczalnia Film�w' and TABLE_NAME ='Klient')
begin
		create table Klient (
		KlientID int identity (1,1) primary key not null,
		Imi� nvarchar (50) not null,
		Nazwisko nvarchar (50) not null,
		Ulica nvarchar (50),
		KodPocztowy nvarchar (10),
		Miasto nvarchar (50) not null,
		NumerTelefonu nvarchar(50) not null,
		NumerDokumentu nvarchar(50) unique,
		obecnyBonus int default 0
)
end;

if not exists (select 1 from INFORMATION_SCHEMA.TABLES WHERE TABLE_CATALOG = 'Wypo�yczalnia Film�w' and TABLE_NAME ='KategoriaFilmu')
begin
		create table KategoriaFilmu (
		KategoriaID int identity (1,1) primary key not null,
		NazwaKategori nvarchar (10) not null,
		CenaPodstawowa money not null,
		Ilo��Dni int,
		CenaDzie�Dodatkowy money,
		PunktyBonusowe int
)
end;

if not exists (select 1 from INFORMATION_SCHEMA.TABLES WHERE TABLE_CATALOG = 'Wypo�yczalnia Film�w' and TABLE_NAME ='HistoriaWypo�ycze�')
begin
		create table HistoriaWypo�ycze� (
		KlientID int not null,
		FilmID int not null,
		primary key (KlientID, FilmID),
		DataWypo�yczenia datetime default getdate(),
		TerminZwrotu datetime,
		DataZwrotu datetime,
		CenaPodstawowa money,
		Dop�ata money,
)	
end;

-- ograniczenia --

alter table HistoriaWypo�ycze�
	add constraint FK_FilmKlient
		foreign key (FilmID) 
		references Film(FilmID)
		on delete cascade

alter table HistoriaWypo�ycze�
	add constraint FK_KlientFilm
		foreign key (KlientID) 
		references Klient(KlientID)
		on delete cascade

alter table Film
	add constraint FK_Kategoria
		foreign key (KategoriaID) 
		references KategoriaFilmu(KategoriaID)
		on delete cascade

alter table Klient
	add constraint Check_KodPocztowy
	check
	(KodPocztowy like '__-___')


-- wype�nianie tabel --

insert into KategoriaFilmu
values ('stary', 30, 5, 30, 1),
	('zwyk�y', 30, 3, 30, 1),
	('nowy', 40, 1, 40, 2);
		

insert into Film
values ('Zielona Mila', 'Dramat', 'Frank Darabont', 1999, 'USA', 1),
	('Avatar', 'Sci-Fi', 'James Cameron', 2009, 'USA', 2),
	('Incepcja', 'Thriller', 'Christopher Nolan', 2010, 'USA', 2),
	('Jestem legend�', 'Sci-Fi', 'Francis Lawrence', 2007, 'USA', 2),
	('Co gryzie Gilberta Grape''a', 'Dramat', 'Lasse Hallstr�m', 1993, 'USA', 1),
	('Jestem taka pi�kna!', 'Komedia', 'Abby Kohn', 2018, 'USA', 4),
	('Atak Paniki', 'Komedia', 'Pawe� Ma�lona', 2017, 'Polska', 4),
	('R�yczka', 'Dramat', 'Jan Kidawa-B�o�ski', 2010, 'Polska', 2)

insert into Klient
values ('Jola','Pierwsza', 'D�uga', '80-300', 'Gda�sk', '569-421-587', 'TGR897563'),
	('Mariola', 'Druga', 'Kr�tka', '87-633', 'Gdynia', '667-801-874', 'KFO897413'),
	('Stefan', 'Trzeci', 'Gruba', '20-654', 'Puck', '601-784-931', 'LMU478541'),
	('Julek', 'Czwarty', 'Chuda', '81-114', 'Gda�sk', '588-784-887', 'OTR784125'),
	('Mirek', 'Pi�ty', 'Ciemna', '82-474', 'Sopot', '501-306-501', 'IUY987321'),
	('Zenon', 'Sz�sty', 'Jasna', '80-236', 'Sopot', '506-987-632', 'MND87125'),
	('Staszka', 'Si�dma', 'Brudna', '81-222', 'Tczew', '690-874-235', 'REW784129'),
	('Jagoda', '�sma', 'Czysta', '85-965', 'Gdynia', '607-854-125', 'OMN774125')


-- obliczanie ceny --

alter function obliczDoplate (@kategoriaID int, @iloscDniKoncowa int)
returns money
as
begin
	
	declare @iloscDni int;
	select @iloscDni = Ilo��Dni from KategoriaFilmu where KategoriaID = @kategoriaID;
	
	declare @cenaPodstawowa money;
	select @cenaPodstawowa = CenaPodstawowa from KategoriaFilmu where KategoriaID = @kategoriaID;

	declare @cenaZaDzienSpoznienia money;
	select  @cenaZaDzienSpoznienia = CenaDzie�Dodatkowy from KategoriaFilmu where KategoriaID = @kategoriaID;

	declare @doplata money;

	if (@iloscDniKoncowa <= @iloscDni)
		return 0
	else
		set @doplata = (@iloscDniKoncowa - @iloscDni) * @cenaZaDzienSpoznienia
		return @doplata
end;
	
select dbo.obliczDoplate (1,4)


-- procedura wypo�yczenia --

alter procedure Wypozyczenie (@klientID int, @filmID int)
as
begin
	declare @cenaPodstawowa money;

	select @cenaPodstawowa = kf.CenaPodstawowa from KategoriaFilmu kf join Film f on kf.KategoriaID = f.KategoriaID
	where f.FilmID = @filmID

	if not exists (select 1 from HistoriaWypo�ycze� where FilmID = @filmID and DataZwrotu is null )
	begin
		insert into HistoriaWypo�ycze� (KlientID, FilmID, DataZwrotu, CenaPodstawowa, Dop�ata)
		values (@klientID, @filmID, null, @cenaPodstawowa, null)
	end
	else
	print 'Film wypo�yczony!'
	
end;


-- procedura zwrotu --

alter procedure zwrotFilmu(@klientID int, @kategoriaID int, @iloscDniKoncowa int)
as
begin
	declare @doplata money;
	set @doplata = dbo.obliczDoplate(@kategoriaID, @iloscDniKoncowa);

	declare @obecnyBonus int;
	select @obecnyBonus = obecnyBonus from Klient where KlientID = @klientID;

	declare @nowyBonus int;
	select @nowyBonus = PunktyBonusowe from KategoriaFilmu where KategoriaID = @kategoriaID;

	update HistoriaWypo�ycze� set DataZwrotu = getdate(), Dop�ata = @doplata where KlientID = @klientID;
	update Klient set obecnyBonus = (@obecnyBonus + @nowyBonus) where KlientID = @klientID
	
end;


-- sprawdzanie --

exec dbo.Wypozyczenie 
exec dbo.zwrotFilmu 

select * from HistoriaWypo�ycze�
select * from KategoriaFilmu
select * from Klient
select * from Film








 













