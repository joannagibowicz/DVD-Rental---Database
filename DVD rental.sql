use [Wypo¿yczalnia Filmów]

-- tworzenie tabel --

if not exists (select 1 from INFORMATION_SCHEMA.TABLES WHERE TABLE_CATALOG = 'Wypo¿yczalnia Filmów' and TABLE_NAME ='Film')
begin
		create table Film (
		FilmID int identity (1,1) primary key not null,
		Tytu³ nvarchar (255) not null,
		GatunekFilmu nvarchar (50),
		Re¿yser nvarchar (50),
		RokProdukcji int,
		KrajProdukcji nvarchar(50),
		KategoriaID int
)
end;

if not exists (select 1 from INFORMATION_SCHEMA.TABLES WHERE TABLE_CATALOG = 'Wypo¿yczalnia Filmów' and TABLE_NAME ='Klient')
begin
		create table Klient (
		KlientID int identity (1,1) primary key not null,
		Imiê nvarchar (50) not null,
		Nazwisko nvarchar (50) not null,
		Ulica nvarchar (50),
		KodPocztowy nvarchar (10),
		Miasto nvarchar (50) not null,
		NumerTelefonu nvarchar(50) not null,
		NumerDokumentu nvarchar(50) unique,
		obecnyBonus int default 0
)
end;

if not exists (select 1 from INFORMATION_SCHEMA.TABLES WHERE TABLE_CATALOG = 'Wypo¿yczalnia Filmów' and TABLE_NAME ='KategoriaFilmu')
begin
		create table KategoriaFilmu (
		KategoriaID int identity (1,1) primary key not null,
		NazwaKategori nvarchar (10) not null,
		CenaPodstawowa money not null,
		IloœæDni int,
		CenaDzieñDodatkowy money,
		PunktyBonusowe int
)
end;

if not exists (select 1 from INFORMATION_SCHEMA.TABLES WHERE TABLE_CATALOG = 'Wypo¿yczalnia Filmów' and TABLE_NAME ='HistoriaWypo¿yczeñ')
begin
		create table HistoriaWypo¿yczeñ (
		KlientID int not null,
		FilmID int not null,
		primary key (KlientID, FilmID),
		DataWypo¿yczenia datetime default getdate(),
		TerminZwrotu datetime,
		DataZwrotu datetime,
		CenaPodstawowa money,
		Dop³ata money,
)	
end;

-- ograniczenia --

alter table HistoriaWypo¿yczeñ
	add constraint FK_FilmKlient
		foreign key (FilmID) 
		references Film(FilmID)
		on delete cascade

alter table HistoriaWypo¿yczeñ
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


-- wype³nianie tabel --

insert into KategoriaFilmu
values ('stary', 30, 5, 30, 1),
	('zwyk³y', 30, 3, 30, 1),
	('nowy', 40, 1, 40, 2);
		

insert into Film
values ('Zielona Mila', 'Dramat', 'Frank Darabont', 1999, 'USA', 1),
	('Avatar', 'Sci-Fi', 'James Cameron', 2009, 'USA', 2),
	('Incepcja', 'Thriller', 'Christopher Nolan', 2010, 'USA', 2),
	('Jestem legend¹', 'Sci-Fi', 'Francis Lawrence', 2007, 'USA', 2),
	('Co gryzie Gilberta Grape''a', 'Dramat', 'Lasse Hallström', 1993, 'USA', 1),
	('Jestem taka piêkna!', 'Komedia', 'Abby Kohn', 2018, 'USA', 4),
	('Atak Paniki', 'Komedia', 'Pawe³ Maœlona', 2017, 'Polska', 4),
	('Ró¿yczka', 'Dramat', 'Jan Kidawa-B³oñski', 2010, 'Polska', 2)

insert into Klient
values ('Jola','Pierwsza', 'D³uga', '80-300', 'Gdañsk', '569-421-587', 'TGR897563'),
	('Mariola', 'Druga', 'Krótka', '87-633', 'Gdynia', '667-801-874', 'KFO897413'),
	('Stefan', 'Trzeci', 'Gruba', '20-654', 'Puck', '601-784-931', 'LMU478541'),
	('Julek', 'Czwarty', 'Chuda', '81-114', 'Gdañsk', '588-784-887', 'OTR784125'),
	('Mirek', 'Pi¹ty', 'Ciemna', '82-474', 'Sopot', '501-306-501', 'IUY987321'),
	('Zenon', 'Szósty', 'Jasna', '80-236', 'Sopot', '506-987-632', 'MND87125'),
	('Staszka', 'Siódma', 'Brudna', '81-222', 'Tczew', '690-874-235', 'REW784129'),
	('Jagoda', 'Ósma', 'Czysta', '85-965', 'Gdynia', '607-854-125', 'OMN774125')


-- obliczanie ceny --

alter function obliczDoplate (@kategoriaID int, @iloscDniKoncowa int)
returns money
as
begin
	
	declare @iloscDni int;
	select @iloscDni = IloœæDni from KategoriaFilmu where KategoriaID = @kategoriaID;
	
	declare @cenaPodstawowa money;
	select @cenaPodstawowa = CenaPodstawowa from KategoriaFilmu where KategoriaID = @kategoriaID;

	declare @cenaZaDzienSpoznienia money;
	select  @cenaZaDzienSpoznienia = CenaDzieñDodatkowy from KategoriaFilmu where KategoriaID = @kategoriaID;

	declare @doplata money;

	if (@iloscDniKoncowa <= @iloscDni)
		return 0
	else
		set @doplata = (@iloscDniKoncowa - @iloscDni) * @cenaZaDzienSpoznienia
		return @doplata
end;
	
select dbo.obliczDoplate (1,4)


-- procedura wypo¿yczenia --

alter procedure Wypozyczenie (@klientID int, @filmID int)
as
begin
	declare @cenaPodstawowa money;

	select @cenaPodstawowa = kf.CenaPodstawowa from KategoriaFilmu kf join Film f on kf.KategoriaID = f.KategoriaID
	where f.FilmID = @filmID

	if not exists (select 1 from HistoriaWypo¿yczeñ where FilmID = @filmID and DataZwrotu is null )
	begin
		insert into HistoriaWypo¿yczeñ (KlientID, FilmID, DataZwrotu, CenaPodstawowa, Dop³ata)
		values (@klientID, @filmID, null, @cenaPodstawowa, null)
	end
	else
	print 'Film wypo¿yczony!'
	
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

	update HistoriaWypo¿yczeñ set DataZwrotu = getdate(), Dop³ata = @doplata where KlientID = @klientID;
	update Klient set obecnyBonus = (@obecnyBonus + @nowyBonus) where KlientID = @klientID
	
end;


-- sprawdzanie --

exec dbo.Wypozyczenie 
exec dbo.zwrotFilmu 

select * from HistoriaWypo¿yczeñ
select * from KategoriaFilmu
select * from Klient
select * from Film








 













