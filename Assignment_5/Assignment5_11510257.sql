create table payment_info(customerid    int not null,
                          card_type     varchar(10) not null
                                        check (card_type in ('VISA',
                                                             'MASTERCARD',
                                                             'UNIONPAY',
                                                             'JCB',
                                                             'AMEX')),
                          card_number   varchar(20) not null)
;
CREATE OR REPLACE FUNCTION luhn_algorithm(card_number varchar) RETURNS boolean AS $luhn_algorithm$
declare
	checksum integer;
	card_number_length integer;
	n_digit integer;
	parity integer;
	digit integer;
BEGIN
	card_number_length = length(card_number);
		--plus the last number
	checksum = CAST(substring(card_number from card_number_length  for 1)AS NUMERIC);
	n_digit = length(card_number);
	parity = n_digit%2;
	FOR i IN 1..n_digit-1 LOOP
		digit = CAST(substring(card_number from i for 1)AS NUMERIC);
		IF i % 2 !=parity THEN
			digit = digit*2;
		END IF;		
		if digit >9 THEN
			digit = digit -9;
		END IF;
		checksum = checksum + digit;
	END LOOP;
	RETURN (checksum % 10)= 0 ;
END;
$luhn_algorithm$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION check_payment_info() RETURNS trigger AS $check_payment_info$
BEGIN
	
	IF NEW.card_type ='VISA' THEN
		--check length
		IF length(NEW.card_number)!=13 AND length(NEW.card_number)!=16 AND length(NEW.card_number)!=19 THEN
			RAISE EXCEPTION 'the length of card number is not right';
		END IF;
		--check IIN/BIN 
		IF 	CAST(substring(NEW.card_number from 1 for 1) AS NUMERIC)!=4 THEN
			RAISE EXCEPTION 'the INN/BIN of card number is not right';
		END IF;
		--check checksum
		IF luhn_algorithm(NEW.card_number)!=true THEN
			RAISE EXCEPTION 'the checksum of card number is not right';
		END IF;
		RETURN NEW;
	END IF;
	
	IF NEW.card_type ='MASTERCARD' THEN
		IF length(NEW.card_number)!=16 THEN
			RAISE EXCEPTION 'the length of card number is not right';
		END IF;
		IF 	CAST(substring(NEW.card_number from 1 for 4) AS NUMERIC)<2221 OR CAST(substring(NEW.card_number from 1 for 4)AS NUMERIC)>2720 
			AND (CAST(substring(NEW.card_number from 1 for 2) AS NUMERIC)<51 OR CAST(substring(NEW.card_number from 1 for 2)AS NUMERIC)>55) THEN
			RAISE EXCEPTION 'the INN/BIN of card number is not right';
		END IF;
		--check checksum
		IF luhn_algorithm(NEW.card_number)!=true THEN
			RAISE EXCEPTION 'the checksum of card number is not right';
		END IF;
		RETURN NEW;
	END IF;

	IF NEW.card_type ='UNIONPAY' THEN
		IF length(NEW.card_number) <16 OR length(NEW.card_number)>19 THEN
			RAISE EXCEPTION 'the length of card number is not right';
		END IF;
		IF 	CAST(substring(NEW.card_number from 1 for 2) AS NUMERIC)!= 62 THEN
			RAISE EXCEPTION 'the INN/BIN of card number is not right';
		END IF;
		--check checksum
		IF luhn_algorithm(NEW.card_number)!=true THEN
			RAISE EXCEPTION 'the checksum of card number is not right';
		END IF;
		RETURN NEW;
	END IF;

	IF NEW.card_type ='JCB' THEN
		IF length(NEW.card_number) <16 OR length(NEW.card_number)>19THEN
			RAISE EXCEPTION 'the length of card number is not right';
		END IF;
		IF 	CAST(substring(NEW.card_number from 1 for 4) AS NUMERIC)<3528 OR CAST(substring(NEW.card_number from 1 for 4)AS NUMERIC)>3589 THEN
			RAISE EXCEPTION 'the INN/BIN of card number is not right';
		END IF;
		--check checksum
		IF luhn_algorithm(NEW.card_number)!=true THEN
			RAISE EXCEPTION 'the checksum of card number is not right';
		END IF;
		RETURN NEW;
	END IF;

	IF NEW.card_type ='AMEX' THEN
		IF length(NEW.card_number)!=15  THEN
			RAISE EXCEPTION 'the length of card number is not right';
		END IF;
		IF 	CAST(substring(NEW.card_number from 1 for 2) AS NUMERIC)!= 34 AND CAST(substring(NEW.card_number from 1 for 2) AS NUMERIC)!= 37 THEN
			RAISE EXCEPTION 'the INN/BIN of card number is not right';
		END IF;
		--check checksum
		IF luhn_algorithm(NEW.card_number)!=true THEN
			RAISE EXCEPTION 'the checksum of card number is not right';
		END IF;
		RETURN NEW;
	END IF;
	
END;
$check_payment_info$ LANGUAGE plpgsql;

CREATE TRIGGER check_payment_info BEFORE INSERT OR UPDATE ON payment_info
FOR EACH ROW EXECUTE PROCEDURE check_payment_info();

